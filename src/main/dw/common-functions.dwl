%dw 2.0

// =============================================================================
// Common Functions Module
// =============================================================================
// Reusable utility functions for GL CSV processing.
// All functions are null-safe and configurable.
// =============================================================================

// --- String Utilities ---

// Safely trim a string value. Returns null if input is null.
// Configurable via rule.trim.strings.enabled
fun trimSafe(value, enabled: Boolean = true) =
    if (enabled and (value != null))
        value as String trim
    else
        value

// Convert null to empty string or omit based on configuration
fun nullToEmpty(value, action: String = "OMIT_FIELD") =
    if (value == null)
        if (action == "EMPTY_STRING") ""
        else null  // OMIT_FIELD behavior
    else value

// --- Numeric Utilities ---

// Safely convert a value to a number. Returns default value on failure.
// Configurable via rule.numeric.safe.conversion.enabled and rule.numeric.default.value
fun toNumberSafe(value, defaultValue: Number = 0, enabled: Boolean = true): Number =
    if (enabled)
        try (value as Number) catch (e: Exception) defaultValue
    else
        value

// Safely parse a string to a number
fun parseNumberSafe(value: String, defaultValue: Number = 0): Number =
    if (isEmpty(value)) defaultValue
    else try (value as Number) catch (e: Exception) defaultValue

// --- Date Utilities ---

// Parse a date string from input format and output in target format.
// Configurable via rule.date.input.format and rule.date.output.format
fun convertDateFormat(dateValue, inputFormat: String = "MM/dd/yyyy", outputFormat: String = "yyyy-MM-dd"): String =
    if (dateValue == null or (dateValue as String).isEmpty())
        null
    else
        try (
            ((dateValue as String) trim) as Date {format: inputFormat}
        ) as String {format: outputFormat}
        catch (e: Exception) null

// Parse date with fallback formats
fun parseDateFlexible(dateValue: String): String =
    if (isEmpty(dateValue)) null
    else (
        try ((dateValue trim) as Date {format: "MM/dd/yyyy"}) as String {format: "yyyy-MM-dd"}
        catch (e: Exception) (
            try ((dateValue trim) as Date {format: "yyyy-MM-dd"}) as String {format: "yyyy-MM-dd"}
            catch (e2: Exception) (
                try ((dateValue trim) as Date {format: "M/d/yyyy"}) as String {format: "yyyy-MM-dd"}
                catch (e3: Exception) null
            )
        )
    )

// --- Validation Utilities ---

// Check if a string is null or empty
fun isEmpty(value): Boolean =
    value == null or ((value as String) trim) == ""

// Check if an amount is valid (greater than threshold)
fun isValidAmount(amount: Number, threshold: Number = 0): Boolean =
    amount > threshold

// Validate that all required fields are present
fun validateRequiredFields(record, requiredFields: Array<String>): Array<String> =
    requiredFields filter (field -> isEmpty(record[field]))

// --- Mapping Utilities ---

// Safely map a field value, applying configured transformations
fun mapField(value, transformations: Array<Function>) =
    transformations reduce ((transform, acc) -> transform(acc), value)

// Omit null values from an object
fun omitNulls(obj: Object): Object =
    obj filterObject ((value, key, index) -> value != null)

// --- String Operations ---
fun escapeCsvValue(value: String): String =
    if (value contains "," or value contains "\"" or value contains "\n")
        "\"" ++ (value replace "\"" with "\"\"") ++ "\""
    else
        value
