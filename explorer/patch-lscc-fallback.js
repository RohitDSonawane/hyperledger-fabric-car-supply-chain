const fs = require('fs');

const candidates = [
    '/opt/explorer/app/platform/fabric/gateway/FabricGateway.js',
    '/opt/explorer/dist/app/platform/fabric/gateway/FabricGateway.js',
    '/opt/explorer/build/app/platform/fabric/gateway/FabricGateway.js'
];

const patterns = [
    {
        name: 'strict-legacy-let',
        regex: /let\s+contract\s*=\s*network\.getContract\(['"]lscc['"]\);\s*[\r\n]+\s*let\s+result\s*=\s*await\s+contract\.evaluateTransaction\(['"]GetChaincodes['"]\);\s*[\r\n]+\s*let\s+resultJson\s*=\s*fabprotos\.protos\.ChaincodeQueryResponse\.decode\(result\);/m,
        replacement:
            "let contract;\n\t\tlet result;\n\t\tlet resultJson = { chaincodes: [], toJSON: null };\n\t\ttry {\n\t\t\tcontract = network.getContract('lscc');\n\t\t\tresult = await contract.evaluateTransaction('GetChaincodes');\n\t\t\tresultJson = fabprotos.protos.ChaincodeQueryResponse.decode(result);\n\t\t} catch (error) {\n\t\t\tlogger.warn('LSCC query failed, fallback to _lifecycle QueryChaincodeDefinitions', error && error.message ? error.message : error);\n\t\t}"
    },
    {
        name: 'generic-declaration',
        regex: /(?:const|let|var)\s+(\w+)\s*=\s*network\.getContract\(['"]lscc['"]\)\s*;\s*(?:const|let|var)\s+(\w+)\s*=\s*await\s+\1\.evaluateTransaction\(['"]GetChaincodes['"]\)\s*;\s*(?:const|let|var)\s+(\w+)\s*=\s*((?:[A-Za-z_$][\w$]*\.)+[A-Za-z_$][\w$]*\.decode)\(\2\)\s*;/m,
        replacement:
            "let $1;\n\t\tlet $2;\n\t\tlet $3 = { chaincodes: [], toJSON: null };\n\t\ttry {\n\t\t\t$1 = network.getContract('lscc');\n\t\t\t$2 = await $1.evaluateTransaction('GetChaincodes');\n\t\t\t$3 = $4($2);\n\t\t} catch (error) {\n\t\t\tlogger.warn('LSCC query failed, fallback to _lifecycle QueryChaincodeDefinitions', error && error.message ? error.message : error);\n\t\t}"
    },
    {
        name: 'lscc-evaluate-call-only',
        regex: /(\w+)\s*=\s*await\s*(\w+)\.evaluateTransaction\(['"]GetChaincodes['"]\)\s*;/m,
        replacement:
            "try {\n\t\t\t$1 = await $2.evaluateTransaction('GetChaincodes');\n\t\t} catch (error) {\n\t\t\tlogger.warn('LSCC GetChaincodes failed, fallback to _lifecycle QueryChaincodeDefinitions', error && error.message ? error.message : error);\n\t\t\t$1 = null;\n\t\t}"
    }
];

function withSafeDecodeWrapper(source) {
    const marker = '__safeDecodeChaincodeQueryResponse';
    let next = source;

    if (!next.includes(`function ${marker}(`)) {
        const strictHeader = "'use strict';";
        const helper =
            "\nfunction __safeDecodeChaincodeQueryResponse(decodeFn, payload) {\n" +
            "    const empty = { chaincodes: [], toJSON: () => ({ chaincodes: [] }) };\n" +
            "    if (!payload || (typeof payload.length === 'number' && payload.length === 0)) {\n" +
            "        return empty;\n" +
            "    }\n" +
            "    try {\n" +
            "        return decodeFn(payload);\n" +
            "    } catch (error) {\n" +
            "        const message = error && error.message ? error.message : error;\n" +
            "        try {\n" +
            "            if (typeof logger !== 'undefined' && logger && typeof logger.warn === 'function') {\n" +
            "                logger.warn('Safe decode fallback for ChaincodeQueryResponse', message);\n" +
            "            } else {\n" +
            "                console.warn('[patch-lscc-fallback] Safe decode fallback', message);\n" +
            "            }\n" +
            "        } catch (_) {}\n" +
            "        return empty;\n" +
            "    }\n" +
            "}\n";

        if (next.includes(strictHeader)) {
            next = next.replace(strictHeader, `${strictHeader}${helper}`);
        } else {
            next = `${helper}${next}`;
        }
    }

    const decodeCallRegex = /((?:[A-Za-z_$][\w$]*\.)+ChaincodeQueryResponse\.decode)\(([^)]+)\)/g;
    if (decodeCallRegex.test(next)) {
        next = next.replace(
            decodeCallRegex,
            '__safeDecodeChaincodeQueryResponse($1, $2)'
        );
    }

    return next;
}

let patched = false;
let scanned = 0;

for (const file of candidates) {
    if (!fs.existsSync(file)) {
        continue;
    }
    scanned += 1;
    const src = fs.readFileSync(file, 'utf8');

    if (!/getContract\(['"]lscc['"]\)/.test(src)) {
        console.log(`[patch-lscc-fallback] Skipped ${file}: lscc contract call not present (possibly already fixed)`);
        continue;
    }

    let next = src;
    let appliedPattern = null;

    for (const pattern of patterns) {
        if (pattern.regex.test(next)) {
            next = next.replace(pattern.regex, pattern.replacement);
            appliedPattern = pattern.name;
            break;
        }
    }

    if (!appliedPattern) {
        // Fallback strategy for transpiled builds: guard GetChaincodes evaluate call
        // and decode path without assuming contiguous statement layout.
        let fallbackPatched = false;

        const evalCallSingle = "evaluateTransaction('GetChaincodes')";
        const evalCallDouble = 'evaluateTransaction("GetChaincodes")';
        const evalReplacement =
            "evaluateTransaction('GetChaincodes').catch((error) => { logger.warn('LSCC GetChaincodes failed, fallback to _lifecycle QueryChaincodeDefinitions', error && error.message ? error.message : error); return null; })";

        if (next.includes(evalCallSingle)) {
            next = next.split(evalCallSingle).join(evalReplacement);
            fallbackPatched = true;
        }
        if (next.includes(evalCallDouble)) {
            next = next.split(evalCallDouble).join(evalReplacement);
            fallbackPatched = true;
        }

        const wrappedDecode = withSafeDecodeWrapper(next);
        if (wrappedDecode !== next) {
            next = wrappedDecode;
            fallbackPatched = true;
        }

        if (fallbackPatched) {
            fs.writeFileSync(file, next, 'utf8');
            console.log(`[patch-lscc-fallback] Applied fallback patch to ${file} using text guards`);
            patched = true;
            break;
        }

        const lines = src.split(/\r?\n/);
        const interestingIndexes = [];
        for (let i = 0; i < lines.length; i += 1) {
            if (
                lines[i].includes('queryInstantiatedChaincodes') ||
                lines[i].includes('lscc') ||
                lines[i].includes('GetChaincodes') ||
                lines[i].includes('QueryChaincodeDefinitions') ||
                lines[i].includes('ChaincodeQueryResponse.decode')
            ) {
                interestingIndexes.push(i);
            }
        }

        console.log(`[patch-lscc-fallback] Skipped ${file}: pattern layout differs`);
        if (interestingIndexes.length > 0) {
            const dumpSet = new Set();
            for (const idx of interestingIndexes.slice(0, 12)) {
                for (let j = Math.max(0, idx - 1); j <= Math.min(lines.length - 1, idx + 1); j += 1) {
                    dumpSet.add(j);
                }
            }
            const ordered = Array.from(dumpSet).sort((a, b) => a - b);
            console.log(`[patch-lscc-fallback] Context dump from ${file}:`);
            for (const lineIdx of ordered) {
                console.log(`[patch-lscc-fallback] ${lineIdx + 1}: ${lines[lineIdx]}`);
            }
        }
        continue;
    }

    // If we applied the minimal evaluate-call patch, also guard decode(result)
    // so null results from LSCC fallback won't crash before _lifecycle query.
    if (appliedPattern === 'lscc-evaluate-call-only') {
        const decodeGuardRegex = /(\w+)\s*=\s*((?:[A-Za-z_$][\w$]*\.)+[A-Za-z_$][\w$]*\.decode)\((\w+)\)\s*;/m;
        if (decodeGuardRegex.test(next)) {
            next = next.replace(
                decodeGuardRegex,
                '$1 = $3 ? $2($3) : { chaincodes: [], toJSON: null };'
            );
        }
    }

    next = withSafeDecodeWrapper(next);
    fs.writeFileSync(file, next, 'utf8');
    console.log(`[patch-lscc-fallback] Applied patch to ${file} using pattern ${appliedPattern}`);
    patched = true;
    break;
}

if (!patched) {
    if (scanned === 0) {
        console.log('[patch-lscc-fallback] No FabricGateway.js candidate file found, continuing startup');
    } else {
        console.log('[patch-lscc-fallback] No patch applied; continuing startup without blocking');
    }
}

process.exit(0);
