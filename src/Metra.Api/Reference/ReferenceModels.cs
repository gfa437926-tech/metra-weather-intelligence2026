using System.Text.Json.Serialization;

namespace Metra.Api.Reference;

public sealed record ObservationTypeItem(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("type_code")] string TypeCode,
    [property: JsonPropertyName("name_ar")] string NameAr,
    [property: JsonPropertyName("name_en")] string NameEn,
    [property: JsonPropertyName("cadence_code")] string? CadenceCode,
    [property: JsonPropertyName("schema_version")] string SchemaVersion);

public sealed record ParameterItem(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("parameter_code")] string ParameterCode,
    [property: JsonPropertyName("name_ar")] string NameAr,
    [property: JsonPropertyName("name_en")] string NameEn,
    [property: JsonPropertyName("description")] string? Description,
    [property: JsonPropertyName("value_kind")] string ValueKind,
    [property: JsonPropertyName("canonical_unit_id")] Guid? CanonicalUnitId,
    [property: JsonPropertyName("unit_code")] string? UnitCode,
    [property: JsonPropertyName("unit_symbol")] string? UnitSymbol,
    [property: JsonPropertyName("precision_scale")] short? PrecisionScale,
    [property: JsonPropertyName("definition_version")] string DefinitionVersion);
