%dw 2.0

// =============================================================================
// Field Mapping Module
// =============================================================================
// Generic, reusable mapping module that transforms source CSV fields to
// target payload fields based on a mapping configuration.
//
// No hardcoded field names or IDs. All mappings are data-driven.
// =============================================================================

import * from common-functions

// --- Dynamic Field Mapping ---

// Maps source fields to target fields based on a provided mapping definition.
// mappingConfig: Array of { sourceField: String, targetField: String, transform: String, defaultValue: Any }
fun applyFieldMapping(source: Object, mappingConfig: Array): Object =
    mappingConfig
        reduce ((mapping, acc: Object) -> {
            (acc),
            (mapping.targetField): transformField(
                source[mapping.sourceField],
                mapping.transform default "direct",
                mapping.defaultValue default null,
                mapping.parameters default {}
            )
        }, {})

// Applies a specific transformation to a field value
fun transformField(value, transformType: String, defaultValue: Any, parameters: Object): Any =
    switch (transformType) {
        "direct" -> value
        "trim" -> trimSafe(value)
        "toNumber" -> parseNumberSafe(value as String, defaultValue as Number)
        "toDate" -> convertDateFormat(value, 
            parameters.inputFormat default "MM/dd/yyyy",
            parameters.outputFormat default "yyyy-MM-dd"
        )
        "boolean" -> value as Boolean default defaultValue
        "upperCase" -> trimSafe(value) upper
        "lowerCase" -> trimSafe(value) lower
        "nullToEmpty" -> nullToEmpty(value, parameters.action default "OMIT_FIELD")
        "skipIfNull" -> if (isEmpty(value)) null else value
        else -> value
    }

// --- Batch Mapping ---

// Apply field mapping to an array of source records
fun mapBatch(sourceRecords: Array, mappingConfig: Array): Array =
    sourceRecords map ((record) -> applyFieldMapping(record, mappingConfig))

// --- Mapping Matrix Generation ---

// Generate a mapping matrix showing source fields and suggested target entities
fun generateMappingMatrix(sourceFields: Array, knownMappings: Object): Array =
    sourceFields map ((field) -> {
        sourceField: field,
        suggestedTarget: knownMappings[field] default "REQUIRES CLIENT CONFIRMATION",
        confidence: if (knownMappings[field] != null) "HIGH" else "LOW"
    })
