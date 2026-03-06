/* Copyright (C) 2026 Daniel Gao <daniel.gao.work@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, see <https://www.gnu.org/licenses/>.
 */

#include "parse_gir.h"

#include <fmt/format.h>
#include <tinyxml2.h>

#include <algorithm>
#include <functional>

#define LOG_ERROR(lineno, msg) \
    m_has_errors = true; \
    fmt::println(stderr, "ERROR (line={}): {}", lineno, msg);

#define LOG_ERRORV(lineno, fmt_str, ...) \
    m_has_errors = true; \
    fmt::print(stderr, "ERROR (line={}): ", lineno); \
    fmt::println(stderr, fmt_str, __VA_ARGS__);

using namespace gir;
using namespace tinyxml2;

namespace {

constexpr const char* const ALIAS_ELEMENT = "alias";
constexpr const char* const ANNOTATION_ELEMENT = "attribute";
constexpr const char* const ARRAY_ELEMENT = "array";
constexpr const char* const BITFIELD_ELEMENT = "bitfield";
constexpr const char* const CALLABLE_PARAMS_ELEMENT = "parameters";
constexpr const char* const CALLABLE_RETURN_ELEMENT = "return-value";
constexpr const char* const CALLBACK_ELEMENT = "callback";
constexpr const char* const CLASS_ELEMENT = "class";
constexpr const char* const CONSTANT_ELEMENT = "constant";
constexpr const char* const CONSTRUCTOR_ELEMENT = "constructor";
constexpr const char* const DOC_ELEMENT = "doc";
constexpr const char* const DOCSECTION_ELEMENT = "docsection";
constexpr const char* const ENUM_ELEMENT = "enumeration";
constexpr const char* const FIELD_ELEMENT = "field";
constexpr const char* const FUNCTION_ELEMENT = "function";
constexpr const char* const FUNCTION_INLINE_ELEMENT = "function-inline";
constexpr const char* const FUNCTION_MACRO_ELEMENT = "function-macro";
constexpr const char* const IMPLEMENTS_ELEMENT = "implements";
constexpr const char* const INTERFACE_ELEMENT = "interface";
constexpr const char* const INSTANCE_PARAMETER_ELEMENT = "instance-parameter";
constexpr const char* const MEMBER_ELEMENT = "member";
constexpr const char* const METHOD_ELEMENT = "method";
constexpr const char* const METHOD_INLINE_ELEMENT = "method-inline";
constexpr const char* const NAMESPACE_ELEMENT = "namespace";
constexpr const char* const PARAMETER_ELEMENT = "parameter";
constexpr const char* const PREREQUISITE_ELEMENT = "prerequisite";
constexpr const char* const PROPERTY_ELEMENT = "property";
constexpr const char* const RECORD_ELEMENT = "record";
constexpr const char* const SIGNAL_ELEMENT = "glib:signal";
constexpr const char* const SOURCE_POSITION_ELEMENT = "source-position";
constexpr const char* const TYPE_ELEMENT = "type";
constexpr const char* const UNION_ELEMENT = "union";
constexpr const char* const VAR_ARGS_ELEMENT = "varargs";
constexpr const char* const VIRTUAL_METHOD_ELEMENT = "virtual-method";

constexpr const char* const OWNERSHIP_ATTR = "transfer-ownership";

bool parse_noop(const XMLAttribute*, std::string_view) { return false; }

class Parser
{
public:
    using ParseExtraAttributes =
        std::function<bool(const XMLAttribute*, std::string_view)>;

    struct WorkingNamespaceScope
    {
        Parser* m_parser;

        WorkingNamespaceScope(Parser* parser, Namespace* ns) : m_parser(parser)
        {
            m_parser->m_working_namespace = ns;
        }
        ~WorkingNamespaceScope() { m_parser->m_working_namespace = nullptr; }
    };

    Parser(const ParseArgs& args)
        : m_warn_unknown(args.warn_unknown),
          m_warn_ignored(args.warn_ignored),
          m_warn_deprecated(args.warn_deprecated)
    {}

    Repository parse_repo(const XMLDocument& doc);

    Bitfield parse_bitfield(const XMLElement* element);
    Enum parse_enum(const XMLElement* element);

    Type* parse_type(const XMLElement* element);
    ArrayType* parse_array_type(const XMLElement* element);

    Param parse_param(const XMLElement* element);
    InstanceParam parse_instance_param(const XMLElement* element);

    Alias parse_alias(const XMLElement* element);
    Annotation parse_annotation(const XMLElement* element);
    CallableParams parse_callable_params(const XMLElement* element,
                                         bool& found_inst_param);
    CallableReturn parse_callable_return(const XMLElement* element);
    Class parse_class(const XMLElement* element);
    Constructor parse_constructor(const XMLElement* element);
    Documentation parse_doc(const XMLElement* element);
    DocSection parse_doc_section(const XMLElement* element);
    FunctionInline parse_inline_function(const XMLElement* element);
    Function parse_function(const XMLElement* element);
    Implements parse_implements(const XMLElement* element);
    Interface parse_interface(const XMLElement* element);
    Member parse_member(const XMLElement* element);
    MethodInline parse_inline_method(const XMLElement* element);
    Method parse_method(const XMLElement* element);
    Namespace parse_namespace(const XMLElement* element);
    Prerequisite parse_prerequisite(const XMLElement* element);
    Property parse_property(const XMLElement* element);
    Record parse_record(const XMLElement* element);
    Signal parse_signal(const XMLElement* element);
    VirtualMethod parse_virtual_method(const XMLElement* element);

    CallableAttributes parse_callable_attributes(
        const XMLElement* element, std::string_view element_name,
        const ParseExtraAttributes& parse_extra_attributes = parse_noop);
    bool parse_inline_function_elements(const XMLElement* element,
                                        std::string_view element_name,
                                        FunctionInline& function,
                                        bool& found_inst_param);
    bool parse_function_elements(const XMLElement* element,
                                 std::string_view element_name,
                                 Function& function,
                                 bool& found_inst_param);

    bool parse_any_type(const XMLElement* element, std::string_view element_name,
                        AnyType& any_type);
    bool parse_doc_elements(const XMLElement* element, std::string_view element_name,
                            DocElements& doc_elements);
    bool parse_source_position(const XMLAttribute* attr, std::string_view attr_name,
                               SourcePosition& src_pos);
    bool parse_info_attributes(const XMLElement* element, const XMLAttribute* attr,
                               std::string_view attr_name, InfoAttributes& info);
    bool parse_info_elements(const XMLElement* element, std::string_view element_name,
                             InfoElements& info);

    std::optional<bool> parse_opt_bool(const XMLAttribute* attr);
    bool parse_introspectable_as_skippable(const XMLAttribute* attr);
    Dir parse_dir(const XMLAttribute* attr);
    RunSignal parse_run_signal(const XMLAttribute* attr);
    Scope parse_scope(const XMLAttribute* attr);
    Stability parse_stability(const XMLAttribute* attr);
    TransferOwnership parse_ownership(const XMLAttribute* attr);

    std::vector<std::string> parse_id_prefixes(const XMLAttribute* attr);
    std::vector<std::string> parse_symbol_prefixes(const XMLAttribute* attr);

    bool has_errors() const { return m_has_errors; }

private:
    void warn_unknown(const XMLElement* parent, const XMLElement* child) {
        if (m_warn_unknown) {
            fmt::println("WARN (line={}): Unknown '{}' child element '{}'",
                         child->GetLineNum(), parent->Name(), child->Name());
        }
    }
    void warn_unknown(const XMLElement* parent, const XMLAttribute* attr) {
        if (m_warn_unknown) {
            fmt::println("WARN (line={}): Unknown '{}' attribute '{}'",
                         attr->GetLineNum(), parent->Name(), attr->Name());
        }
    }

    void warn_ignored(const XMLElement* parent, const XMLElement* child) {
        if (m_warn_ignored) {
            fmt::println("WARN (line={}): Ignored '{}' child element '{}'",
                         child->GetLineNum(), parent->Name(), child->Name());
        }
    }

    void warn_ignored(const XMLElement* parent, const XMLAttribute* attr) {
        if (m_warn_ignored) {
            fmt::println("WARN (line={}): Ignored '{}' attribute '{}'",
                         attr->GetLineNum(), parent->Name(), attr->Name());
        }
    }

    void warn_deprecated(const XMLElement* parent, const XMLElement* child) {
        if (m_warn_ignored || m_warn_deprecated) {
            fmt::println("WARN (line={}): Ignored '{}' deprecated child element '{}'",
                         child->GetLineNum(), parent->Name(), child->Name());
        }
    }

    void warn_deprecated(const XMLElement* parent, const XMLAttribute* attr) {
        if (m_warn_ignored || m_warn_deprecated) {
            fmt::println("WARN (line={}): Ignored '{}' deprecated attribute '{}'",
                         attr->GetLineNum(), parent->Name(), attr->Name());
        }
    }

    bool populate_str_attr(const XMLElement* element, std::string_view attr,
                           std::string_view pod, std::string& dest);

    Namespace* m_working_namespace = nullptr;
    bool m_warn_unknown = false;
    bool m_warn_ignored = false;
    bool m_warn_deprecated = false;
    bool m_has_errors = false;
};

}  // namespace

std::optional<bool> Parser::parse_opt_bool(const XMLAttribute* attr)
{
    std::string_view value{attr->Value()};

    if (value == "0") {
        return false;
    } else if (value == "1") {
        return true;
    } else {
        LOG_ERRORV(attr->GetLineNum(), "Unknown bool {}", value);
        return std::nullopt;
    }
}

bool Parser::parse_introspectable_as_skippable(const XMLAttribute* attr)
{
    std::string_view value{attr->Value()};

    if (value == "0") {
        // Allowed to skip from language bindings
        return true;
    } else if (value == "1") {
        return false;
    } else {
        LOG_ERRORV(attr->GetLineNum(), "Unknown bool {}", value);
        return false;
    }
}

Dir Parser::parse_dir(const XMLAttribute* attr)
{
    std::string_view value{attr->Value()};

    if (value == "in") return Dir::IN;
    if (value == "out") return Dir::OUT;
    if (value == "inout") return Dir::INOUT;

    LOG_ERRORV(attr->GetLineNum(), "Unknown direction {}", value);
    return Dir::INOUT;
}

RunSignal Parser::parse_run_signal(const XMLAttribute* attr)
{
    std::string_view value{attr->Value()};

    if (value == "first") return RunSignal::FIRST;
    if (value == "last") return RunSignal::LAST;
    if (value == "cleanup") return RunSignal::CLEANUP;

    LOG_ERRORV(attr->GetLineNum(), "Unknown when {}", value);
    return RunSignal::FIRST;
}

Scope Parser::parse_scope(const XMLAttribute* attr)
{
    std::string_view value{attr->Value()};

    if (value == "notified") return Scope::NOTIFIED;
    if (value == "async") return Scope::ASYNC;
    if (value == "call") return Scope::CALL;
    if (value == "forever") return Scope::FOREVER;

    LOG_ERRORV(attr->GetLineNum(), "Unknown scope {}", value);
    return Scope::CALL;
}

Stability Parser::parse_stability(const XMLAttribute* attr)
{
    std::string_view value{attr->Value()};

    if (value == "Stable") return Stability::STABLE;
    if (value == "Unstable") return Stability::UNSTABLE;
    if (value == "Private") return Stability::PRIVATE;

    LOG_ERRORV(attr->GetLineNum(), "Unknown stability {}", value);
    return Stability::UNKNOWN;
}

TransferOwnership Parser::parse_ownership(const XMLAttribute* attr)
{
    std::string_view value{attr->Value()};

    if (value == "none") return TransferOwnership::NONE;
    if (value == "container") return TransferOwnership::CONTAINER;
    if (value == "full") return TransferOwnership::FULL;

    LOG_ERRORV(attr->GetLineNum(), "Unknown ownership {}", value);
    return TransferOwnership::NONE;
}

std::vector<std::string> Parser::parse_id_prefixes(const XMLAttribute* attr)
{
    std::vector<std::string> prefixes;

    std::string_view value{attr->Value()};

    size_t pos = 0;
    size_t found;

    while ((found = value.find(',', pos)) != std::string_view::npos) {
        prefixes.emplace_back(value.substr(pos, found - pos));
        pos = found + 1;
    }
    prefixes.emplace_back(value.substr(pos));

    for (const auto& prefix : prefixes) {
        if (!std::all_of(prefix.begin(), prefix.end(),
                         [](unsigned char c) { return std::isalnum(c); })) {
            LOG_ERRORV(attr->GetLineNum(), "Bad symbol prefix {}", prefix);
        }
    }

    return prefixes;
}

std::vector<std::string> Parser::parse_symbol_prefixes(const XMLAttribute* attr)
{
    std::vector<std::string> prefixes;

    std::string_view value{attr->Value()};

    size_t pos = 0;
    size_t found;

    while ((found = value.find(',', pos)) != std::string_view::npos) {
        prefixes.emplace_back(value.substr(pos, found - pos));
        pos = found + 1;
    }
    prefixes.emplace_back(value.substr(pos));

    for (const auto& prefix : prefixes) {
        if (!std::all_of(prefix.begin(), prefix.end(),
                         [](unsigned char c) { return std::isalnum(c); })) {
            LOG_ERRORV(attr->GetLineNum(), "Bad identifier prefix {}", prefix);
        }
    }

    return prefixes;
}

Repository Parser::parse_repo(const XMLDocument& doc)
{
    const XMLElement* root = doc.FirstChildElement("repository");
    if (!root) {
        throw GirParseError("Root element is not repository");
    }

    Repository repo;

    for (const XMLAttribute* attr = root->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == "version") {
            repo.version = attr->Value();
        } else if (name == "c:identifier-prefixes") {
            repo.identifier_prefixes = parse_id_prefixes(attr);
        } else if (name == "c:symbol-prefixes") {
            repo.symbol_prefixes = parse_symbol_prefixes(attr);
        } else {
            warn_unknown(root, attr);
        }
    }

    for (const XMLElement* child = root->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

         std::string_view name{child->Name()};

        if (name == NAMESPACE_ELEMENT) {
            repo.namespaces.push_back(parse_namespace(child));
        } else {
            warn_unknown(root, child);
        }
    }

    return repo;
}

Bitfield Parser::parse_bitfield(const XMLElement* element)
{
    Bitfield bitfield;

    constexpr const char* const NAME_ATTR = "name";
    constexpr const char* const C_TYPE_ATTR = "c:type";
    populate_str_attr(element, NAME_ATTR, BITFIELD_ELEMENT, bitfield.name);
    populate_str_attr(element, C_TYPE_ATTR, BITFIELD_ELEMENT, bitfield.c_type);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR || name == C_TYPE_ATTR) {
            // Mandatory values already set
        } else if (name == "glib:type-name") {
            bitfield.glib_type_name = attr->Value();
        } else if (name == "glib:get-type") {
            bitfield.glib_type_func = attr->Value();
        } else if (parse_info_attributes(element, attr, name, bitfield.info_attributes)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (name == MEMBER_ELEMENT) {
            bitfield.members.push_back(parse_member(child));
        } else if (name == FUNCTION_INLINE_ELEMENT) {
            bitfield.inline_functions.push_back(parse_inline_function(child));
        } else if (name == FUNCTION_ELEMENT) {
            bitfield.functions.push_back(parse_function(child));
        } else if (parse_info_elements(child, name, bitfield.info_elements)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, child);
        }
    }

    return bitfield;
}

Enum Parser::parse_enum(const XMLElement* element)
{
    Enum parsed;

    constexpr const char* const NAME_ATTR = "name";
    constexpr const char* const C_TYPE_ATTR = "c:type";
    populate_str_attr(element, NAME_ATTR, ENUM_ELEMENT, parsed.name);
    populate_str_attr(element, C_TYPE_ATTR, ENUM_ELEMENT, parsed.c_type);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR || name == C_TYPE_ATTR) {
            // Mandatory values already set
        } else if (name == "glib:type-name") {
            parsed.glib_type_name = attr->Value();
        } else if (name == "glib:get-type") {
            parsed.glib_type_func = attr->Value();
        } else if (name == "glib:error-domain") {
            parsed.error_domain = attr->Value();
        } else if (parse_info_attributes(element, attr, name, parsed.info_attributes)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (name == MEMBER_ELEMENT) {
            parsed.members.push_back(parse_member(child));
        } else if (name == FUNCTION_INLINE_ELEMENT) {
            parsed.inline_functions.push_back(parse_inline_function(child));
        } else if (name == FUNCTION_ELEMENT) {
            parsed.functions.push_back(parse_function(child));
        } else if (parse_info_elements(child, name, parsed.info_elements)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, child);
        }
    }

    return parsed;
}

Type* Parser::parse_type(const XMLElement* element)
{
    auto type = std::make_unique<Type>();

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == "name") {
            type->name = attr->Value();
        } else if (name == "c:type") {
            type->c_type = attr->Value();
        } else if (name == "introspectable") {
            warn_ignored(element, attr);
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (parse_doc_elements(child, name, type->doc_elements)) {
            // Value set as side-effect
        } else if (name == TYPE_ELEMENT || name == ARRAY_ELEMENT) {
            warn_ignored(element, child);
        } else {
            warn_unknown(element, child);
        }
    }

    Type* raw_ptr = type.get();
    m_working_namespace->types.push_back(std::move(type));
    return raw_ptr;
}

ArrayType* Parser::parse_array_type(const XMLElement* element)
{
    auto type = std::make_unique<ArrayType>();

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == "name") {
            type->name = attr->Value();
        } else if (name == "zero-terminated") {
            type->is_zero_terminated = parse_opt_bool(attr);
        } else if (name == "introspectable") {
            warn_ignored(element, attr);
        } else if (name == "fixed-size") {
            type->fixed_size = attr->IntValue();
        } else if (name == "length") {
            type->length = attr->IntValue();
        } else if (name == "c:type") {
            type->c_type = attr->Value();
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (parse_any_type(child, name, type->element_type)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, child);
        }
    }

    ArrayType* raw_ptr = type.get();
    m_working_namespace->array_types.push_back(std::move(type));
    return raw_ptr;
}

Param Parser::parse_param(const XMLElement* element)
{
    Param param;

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == "name") {
            param.name = attr->Value();
        } else if (name == "nullable") {
            param.is_nullable = parse_opt_bool(attr);
        } else if (name == "allow-none") {
            warn_deprecated(element, attr);
        } else if (name == "introspectable") {
            warn_ignored(element, attr);
        } else if (name == "closure") {
            param.closure = attr->IntValue();
        } else if (name == "destroy") {
            param.destroy = attr->IntValue();
        } else if (name == "scope") {
            param.scope = parse_scope(attr);
        } else if (name == "direction") {
            param.direction = parse_dir(attr);
        } else if (name == "caller-allocates") {
            param.is_caller_allocated = parse_opt_bool(attr);
        } else if (name == "optional") {
            param.is_optional = parse_opt_bool(attr);
        } else if (name == "skip") {
            param.is_skippable = parse_opt_bool(attr);
        } else if (name == OWNERSHIP_ATTR) {
            param.ownership = parse_ownership(attr);
        } else {
            warn_unknown(element, attr);
        }
    }

    AnyType tmp_type = static_cast<Type*>(nullptr);

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (parse_info_elements(child, name, param.info_elements)) {
            // Value set as side-effect
        } else if (parse_any_type(child, name, tmp_type)) {
            param.type = tmp_type;
        } else if (name == VAR_ARGS_ELEMENT) {
            param.type = VarArgs{};
        } else {
            warn_unknown(element, child);
        }
    }

    return param;
}

InstanceParam Parser::parse_instance_param(const XMLElement* element)
{
    InstanceParam param;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, BITFIELD_ELEMENT, param.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR) {
            // Mandatory values already set
        } else if (name == "nullable") {
            param.is_nullable = parse_opt_bool(attr);
        } else if (name == "allow-none") {
            warn_deprecated(element, attr);
        } else if (name == "direction") {
            param.direction = parse_dir(attr);
        } else if (name == "caller-allocates") {
            param.is_caller_allocated = parse_opt_bool(attr);
        } else if (name == OWNERSHIP_ATTR) {
            param.ownership = parse_ownership(attr);
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (parse_doc_elements(child, name, param.doc_elements)) {
            // Value set as side-effect
        } else if (name == TYPE_ELEMENT) {
            param.type = parse_type(child);
        } else {
            warn_unknown(element, child);
        }
    }

    return param;
}

Alias Parser::parse_alias(const XMLElement* element)
{
    Alias alias;

    constexpr const char* const NAME_ATTR = "name";
    constexpr const char* const C_TYPE_ATTR = "c:type";
    populate_str_attr(element, NAME_ATTR, ALIAS_ELEMENT, alias.name);
    populate_str_attr(element, C_TYPE_ATTR, ALIAS_ELEMENT, alias.c_type);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR || name == C_TYPE_ATTR) {
            // Mandatory values already set
        } else if (parse_info_attributes(element, attr, name, alias.info_attributes)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, attr);
        }
    }

    AnyType tmp_type = static_cast<Type*>(nullptr);

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (parse_info_elements(child, name, alias.info_elements)) {
            // Value set as side-effect
        } else if (parse_any_type(child, name, tmp_type)) {
            alias.type = tmp_type;
        } else {
            warn_unknown(element, child);
        }
    }

    return alias;
}

Annotation Parser::parse_annotation(const XMLElement* element)
{
    Annotation data;

    constexpr const char* const NAME_ATTR = "name";
    constexpr const char* const VALUE_ATTR = "value";
    populate_str_attr(element, NAME_ATTR, ANNOTATION_ELEMENT, data.name);
    populate_str_attr(element, VALUE_ATTR, ANNOTATION_ELEMENT, data.value);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR || name == VALUE_ATTR) {
            // Mandatory values already set
        } else {
            warn_unknown(element, attr);
        }
    }

    return data;
}

CallableParams Parser::parse_callable_params(const XMLElement* element,
                                             bool& found_inst_param)
{
    CallableParams params;

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (name == PARAMETER_ELEMENT) {
            params.params.push_back(parse_param(child));
        } else if (name == INSTANCE_PARAMETER_ELEMENT) {
            params.instance_param = parse_instance_param(child);
            found_inst_param = true;
        } else {
            warn_unknown(element, child);
        }
    }

    return params;
}

CallableReturn Parser::parse_callable_return(const XMLElement* element)
{
    CallableReturn parsed;

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == "nullable") {
            parsed.is_nullable = parse_opt_bool(attr);
        } else if (name == "closure") {
            parsed.closure = attr->IntValue();
        } else if (name == "scope") {
            parsed.scope = parse_scope(attr);
        } else if (name == "destroy") {
            parsed.destroy = attr->IntValue();
        } else if (name == "skip") {
            parsed.is_skippable = parse_opt_bool(attr);
        } else if (name == "allow-none") {
            warn_deprecated(element, attr);
        } else if (name == OWNERSHIP_ATTR) {
            parsed.ownership = parse_ownership(attr);
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (parse_info_elements(child, name, parsed.info_elements)) {
            // Value set as side-effect
        } else if (parse_any_type(child, name, parsed.type)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, child);
        }
    }

    return parsed;
}

Class Parser::parse_class(const XMLElement* element)
{
    Class klass;

    constexpr const char* const NAME_ATTR = "name";
    constexpr const char* const TYPE_NAME_ATTR = "glib:type-name";
    constexpr const char* const TYPE_FUNC_ATTR = "glib:get-type";
    populate_str_attr(element, NAME_ATTR, INTERFACE_ELEMENT, klass.name);
    populate_str_attr(element, TYPE_NAME_ATTR, INTERFACE_ELEMENT, klass.glib_type_name);
    populate_str_attr(element, TYPE_FUNC_ATTR, INTERFACE_ELEMENT, klass.glib_type_func);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (parse_info_attributes(element, attr, name, klass.info_attributes)) {
            // Value set as side-effect
        } else if (name == NAME_ATTR || name == TYPE_NAME_ATTR
                   || name == TYPE_FUNC_ATTR) {
            // Mandatory values already set
        } else if (name == "parent") {
            klass.parent = attr->Value();
        } else if (name == "glib:type-struct") {
            klass.glib_type_struct = attr->Value();
        } else if (name == "glib:ref-func") {
            klass.glib_ref_func = attr->Value();
        } else if (name == "glib:unref-func") {
            klass.glib_unref_func = attr->Value();
        } else if (name == "glib:set-value-func") {
            klass.glib_set_value_func = attr->Value();
        } else if (name == "glib:get-value-func") {
            klass.glib_get_value_func = attr->Value();
        } else if (name == "c:type") {
            klass.c_type = attr->Value();
        } else if (name == "c:symbol-prefix") {
            klass.symbol_prefix = attr->Value();
        } else if (name == "abstract") {
            klass.is_abstract = parse_opt_bool(attr);
        } else if (name == "glib:fundamental") {
            klass.is_glib_fundamental = parse_opt_bool(attr);
        } else if (name == "final") {
            klass.is_final = parse_opt_bool(attr);
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (parse_info_elements(child, name, klass.info_elements)) {
            // Value set as side-effect
        } else if (name == IMPLEMENTS_ELEMENT) {
            klass.implements.push_back(parse_implements(child));
        } else if (name == CONSTRUCTOR_ELEMENT) {
            klass.constructors.push_back(parse_constructor(child));
        } else if (name == METHOD_ELEMENT) {
            klass.methods.push_back(parse_method(child));
        } else if (name == METHOD_INLINE_ELEMENT) {
            klass.inline_methods.push_back(parse_inline_method(child));
        } else if (name == FUNCTION_ELEMENT) {
            klass.functions.push_back(parse_function(child));
        } else if (name == FUNCTION_INLINE_ELEMENT) {
            klass.inline_functions.push_back(parse_inline_function(child));
        } else if (name == VIRTUAL_METHOD_ELEMENT) {
            klass.virtual_methods.push_back(parse_virtual_method(child));
        } else if (name == PROPERTY_ELEMENT) {
            klass.properties.push_back(parse_property(child));
        } else if (name == SIGNAL_ELEMENT) {
            klass.signals.push_back(parse_signal(child));
        } else if (name == RECORD_ELEMENT) {
            klass.records.push_back(parse_record(child));
        } else if (name == FIELD_ELEMENT || name == CALLBACK_ELEMENT
                   || name == CONSTANT_ELEMENT || name == UNION_ELEMENT) {
            warn_ignored(element, child);
        } else {
            warn_unknown(element, child);
        }
    }

    return klass;
}

Constructor Parser::parse_constructor(const XMLElement* element)
{
    Constructor constructor;
    constructor.func = parse_function(element);
    return constructor;
}

Documentation Parser::parse_doc(const XMLElement* element)
{
    Documentation doc;

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        parse_source_position(attr, attr->Name(), doc.src_pos);
    }

    const char* text = element->GetText();
    if (!text) {
        LOG_ERROR(element->GetLineNum(), "Doc is missing text");
    } else {
        doc.text = text;
    }

    return doc;
}

DocSection Parser::parse_doc_section(const XMLElement* element)
{
    DocSection doc;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, DOCSECTION_ELEMENT, doc.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR) {
            // Mandatory values already set
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (!parse_doc_elements(child, name, doc.doc_elements)) {
            warn_unknown(element, child);
        }
    }

    return doc;
}

FunctionInline Parser::parse_inline_function(const XMLElement* element)
{
    FunctionInline function;

    function.attributes = parse_callable_attributes(element, FUNCTION_INLINE_ELEMENT);

    bool found_inst_param = false;
    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (!parse_inline_function_elements(child, name, function, found_inst_param)) {
            warn_unknown(element, child);
        }
    }

    if (found_inst_param) {
        LOG_ERRORV(element->GetLineNum(), "Free function '{}' takes instance parameter",
                   function.attributes.name);
    }

    return function;
}

Function Parser::parse_function(const XMLElement* element)
{
    Function function;
    function.detail.attributes = parse_callable_attributes(element, FUNCTION_ELEMENT);

    bool found_inst_param = false;
    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (!parse_function_elements(child, name, function, found_inst_param)) {
            warn_unknown(element, child);
        }
    }

    if (found_inst_param) {
        LOG_ERRORV(element->GetLineNum(), "Free function '{}' takes instance parameter",
                   function.detail.attributes.name);
    }

    return function;
}

Implements Parser::parse_implements(const XMLElement* element)
{
    Implements impl;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, IMPLEMENTS_ELEMENT, impl.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name != NAME_ATTR) {
            warn_unknown(element, attr);
        }
    }

    return impl;
}

Interface Parser::parse_interface(const XMLElement* element)
{
    Interface interface;

    constexpr const char* const NAME_ATTR = "name";
    constexpr const char* const TYPE_NAME_ATTR = "glib:type-name";
    constexpr const char* const TYPE_FUNC_ATTR = "glib:get-type";
    populate_str_attr(element, NAME_ATTR, INTERFACE_ELEMENT, interface.name);
    populate_str_attr(element, TYPE_NAME_ATTR, INTERFACE_ELEMENT,
                      interface.glib_type_name);
    populate_str_attr(element, TYPE_FUNC_ATTR, INTERFACE_ELEMENT,
                      interface.glib_type_func);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (parse_info_attributes(element, attr, name, interface.info_attributes)) {
            // Value set as side-effect
        } else if (name == NAME_ATTR || name == TYPE_NAME_ATTR
                   || name == TYPE_FUNC_ATTR) {
            // Mandatory values already set
        } else if (name == "c:symbol-prefix") {
            interface.symbol_prefix = attr->Value();
        } else if (name == "c:type") {
            interface.c_type = attr->Value();
        } else if (name == "glib:type-struct") {
            interface.glib_type_struct = attr->Value();
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (parse_info_elements(child, name, interface.info_elements)) {
            // Value set as side-effect
        } else if (name == PREREQUISITE_ELEMENT) {
            interface.prerequisites.push_back(parse_prerequisite(child));
        } else if (name == IMPLEMENTS_ELEMENT) {
            interface.implements.push_back(parse_implements(child));
        } else if (name == FUNCTION_ELEMENT) {
            interface.functions.push_back(parse_function(child));
        } else if (name == FUNCTION_INLINE_ELEMENT) {
            interface.inline_functions.push_back(parse_inline_function(child));
        } else if (name == CONSTRUCTOR_ELEMENT) {
            interface.constructor = parse_constructor(child);
        } else if (name == METHOD_ELEMENT) {
            interface.methods.push_back(parse_method(child));
        } else if (name == METHOD_INLINE_ELEMENT) {
            interface.inline_methods.push_back(parse_inline_method(child));
        } else if (name == VIRTUAL_METHOD_ELEMENT) {
            interface.virtual_methods.push_back(parse_virtual_method(child));
        } else if (name == PROPERTY_ELEMENT) {
            interface.properties.push_back(parse_property(child));
        } else if (name == SIGNAL_ELEMENT) {
            interface.signals.push_back(parse_signal(child));
        } else if (name == FIELD_ELEMENT || name == CALLBACK_ELEMENT
                   || name == CONSTANT_ELEMENT) {
            warn_ignored(element, child);
        } else {
            warn_unknown(element, child);
        }
    }

    return interface;
}

Member Parser::parse_member(const XMLElement* element)
{
    Member member;

    constexpr const char* const NAME_ATTR = "name";
    constexpr const char* const VALUE_ATTR = "value";
    constexpr const char* const C_IDENTIFIER_ATTR = "c:identifier";
    populate_str_attr(element, NAME_ATTR, MEMBER_ELEMENT, member.name);
    populate_str_attr(element, VALUE_ATTR, MEMBER_ELEMENT, member.value);
    populate_str_attr(element, C_IDENTIFIER_ATTR, MEMBER_ELEMENT, member.c_identifier);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR || name == VALUE_ATTR || name == C_IDENTIFIER_ATTR) {
            // Mandatory values already set
        } else if (name == "glib:nick") {
            member.nickname = attr->Value();
        } else if (name == "glib:name") {
            warn_ignored(element, attr);
        } else if (parse_info_attributes(element, attr, name, member.info_attributes)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (!parse_info_elements(child, name, member.info_elements)) {
            warn_unknown(element, child);
        }
    }

    return member;
}

MethodInline Parser::parse_inline_method(const XMLElement* element)
{
    MethodInline method;

    method.func.detail.attributes =
        parse_callable_attributes(element, METHOD_INLINE_ELEMENT);

    bool found_inst_param = false;
    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (!parse_function_elements(child, name, method.func, found_inst_param)) {
            warn_unknown(element, child);
        }
    }

    if (!found_inst_param) {
        LOG_ERRORV(element->GetLineNum(), "Method '{}' missing instance parameter",
                   method.func.detail.attributes.name);
    }

    return method;
}

Method Parser::parse_method(const XMLElement* element)
{
    Method method;

    auto parse_extra_attributes =
        [&](const XMLAttribute* attr, std::string_view attr_name) -> bool {
            if (attr_name == "glib:set-property") {
                method.set_property = attr->Value();
                return true;
            } else if (attr_name == "glib:get-property") {
                method.get_property = attr->Value();
                return true;
            } else {
                return false;
            }
        };
    method.func.detail.attributes =
        parse_callable_attributes(element, METHOD_ELEMENT, parse_extra_attributes);

    bool found_inst_param = false;
    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (!parse_function_elements(child, name, method.func, found_inst_param)) {
            warn_unknown(element, child);
        }
    }

    if (!found_inst_param) {
        LOG_ERRORV(element->GetLineNum(), "Method '{}' missing instance parameter",
                   method.func.detail.attributes.name);
    }

    return method;
}

Namespace Parser::parse_namespace(const XMLElement* element)
{
    Namespace ns;
    WorkingNamespaceScope working_scope(this, &ns);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == "name") {
            ns.name = attr->Value();
        } else if (name == "version") {
            ns.version = attr->Value();
        } else if (name == "c:identifier-prefixes") {
            ns.identifier_prefixes = parse_id_prefixes(attr);
        } else if (name == "c:symbol-prefixes") {
            ns.symbol_prefixes = parse_symbol_prefixes(attr);
        } else if (name == "c:prefix") {
            warn_deprecated(element, attr);
        } else if (name == "shared-library") {
            warn_ignored(element, attr);
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};
        if (name == ALIAS_ELEMENT) {
            ns.aliases.push_back(parse_alias(child));
        } else if (name == CLASS_ELEMENT) {
            ns.classes.push_back(parse_class(child));
        } else if (name == INTERFACE_ELEMENT) {
            ns.interfaces.push_back(parse_interface(child));
        } else if (name == RECORD_ELEMENT) {
            ns.records.push_back(parse_record(child));
        } else if (name == ENUM_ELEMENT) {
            ns.enums.push_back(parse_enum(child));
        } else if (name == FUNCTION_ELEMENT) {
            ns.functions.push_back(parse_function(child));
        } else if (name == FUNCTION_INLINE_ELEMENT) {
            ns.inline_functions.push_back(parse_inline_function(child));
        } else if (name == FUNCTION_MACRO_ELEMENT) {
            warn_ignored(element, child);
        } else if (name == BITFIELD_ELEMENT) {
            ns.bitfields.push_back(parse_bitfield(child));
        } else if (name == ANNOTATION_ELEMENT) {
            ns.annotations.push_back(parse_annotation(child));
        } else if (name == DOCSECTION_ELEMENT) {
            ns.doc_sections.push_back(parse_doc_section(child));
        } else if (name == ALIAS_ELEMENT || name == CALLBACK_ELEMENT
                   || name == CONSTANT_ELEMENT) {
            warn_ignored(element, child);
        } else {
            warn_unknown(element, child);
        }
    }

    if (!ns.name) {
        LOG_ERROR(element->GetLineNum(), "Namespace without a name is not supported!");
    }

    return ns;
}

Prerequisite Parser::parse_prerequisite(const XMLElement* element)
{
    Prerequisite prerequisite;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, PREREQUISITE_ELEMENT, prerequisite.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name != NAME_ATTR) {
            warn_unknown(element, attr);
        }
    }

    return prerequisite;
}

Property Parser::parse_property(const XMLElement* element)
{
    Property property;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, PROPERTY_ELEMENT, property.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR) {
            // Mandatory values already set
        } else if (parse_info_attributes(element, attr, name, property.info_attributes)) {
            // Value set as side-effect
        } else if (name == "writable") {
            property.is_writable = parse_opt_bool(attr);
        } else if (name == "readable") {
            property.is_readable = parse_opt_bool(attr);
        } else if (name == "construct") {
            property.is_set_on_construction = parse_opt_bool(attr);
        } else if (name == "construct-only") {
            property.is_set_only_during_construction = parse_opt_bool(attr);
        } else if (name == "setter") {
            property.setter_func = attr->Value();
        } else if (name == "getter") {
            property.getter_func = attr->Value();
        } else if (name == "default-value") {
            property.default_value = attr->Value();
        } else if (name == OWNERSHIP_ATTR) {
            property.ownership = parse_ownership(attr);
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (parse_info_elements(child, name, property.info_elements)) {
            // Value set as side-effect
        } else if (parse_any_type(child, name, property.type)) {
            // Value set as side-effect
        } else {
            warn_unknown(element, child);
        }
    }

    return property;
}

Record Parser::parse_record(const XMLElement* element)
{
    Record record;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, RECORD_ELEMENT, record.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR) {
            // Mandatory values already set
        } else if (parse_info_attributes(element, attr, name, record.info_attributes)) {
            // Value set as side-effect
        } else if (name == "c:type") {
            record.c_type = attr->Value();
        } else if (name == "disguised") {
            warn_deprecated(element, attr);
        } else if (name == "opaque") {
            record.is_opaque = parse_opt_bool(attr);
        } else if (name == "pointer") {
            record.is_disguised_pointer = parse_opt_bool(attr);
        } else if (name == "glib:type-name") {
            record.glib_type_name = attr->Value();
        } else if (name == "glib:get-type") {
            record.glib_type_func = attr->Value();
        } else if (name == "c:symbol-prefix") {
            warn_ignored(element, attr);
        } else if (name == "foreign") {
            record.is_foreign = parse_opt_bool(attr);
        } else if (name == "glib:is-gtype-struct-for") {
            record.for_gtype_struct = attr->Value();
        } else if (name == "copy-function") {
            record.copy_function = attr->Value();
        } else if (name == "free-function") {
            record.free_function = attr->Value();
        } else {
            warn_unknown(element, attr);
        }
    }

    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (parse_info_elements(child, name, record.info_elements)) {
            // Value set as side-effect
        } else if (name == FIELD_ELEMENT) {
            warn_ignored(element, child);
        } else if (name == FUNCTION_ELEMENT) {
            record.functions.push_back(parse_function(child));
        } else if (name == FUNCTION_INLINE_ELEMENT) {
            record.inline_functions.push_back(parse_inline_function(child));
        } else if (name == UNION_ELEMENT) {
            warn_ignored(element, child);
        } else if (name == METHOD_ELEMENT) {
            record.methods.push_back(parse_method(child));
        } else if (name == METHOD_INLINE_ELEMENT) {
            record.inline_methods.push_back(parse_inline_method(child));
        } else if (name == CONSTRUCTOR_ELEMENT) {
            record.constructors.push_back(parse_constructor(child));
        } else {
            warn_unknown(element, child);
        }
    }
    return record;
}

Signal Parser::parse_signal(const XMLElement* element)
{
    Signal signal;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, SIGNAL_ELEMENT, signal.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view name{attr->Name()};

        if (name == NAME_ATTR) {
            // Mandatory values already set
        } else if (parse_info_attributes(element, attr, name, signal.info_attributes)) {
            // Value set as side-effect
        } else if (name == "detailed") {
            signal.is_detailed = parse_opt_bool(attr);
        } else if (name == "when") {
            signal.when = parse_run_signal(attr);
        } else if (name == "action") {
            signal.is_action = parse_opt_bool(attr);
        } else if (name == "no-hooks") {
            signal.no_hooks = parse_opt_bool(attr);
        } else if (name == "no-recurse") {
            signal.no_recurse = parse_opt_bool(attr);
        } else if (name == "emitter") {
            signal.emitter = attr->Value();
        } else {
            warn_unknown(element, attr);
        }
    }

    bool found_inst_param = false;
    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (parse_info_elements(child, name, signal.info_elements)) {
            // Value set as side-effect
        } else if (name == CALLABLE_PARAMS_ELEMENT) {
            signal.params = parse_callable_params(child, found_inst_param);
        } else if (name == CALLABLE_RETURN_ELEMENT) {
            signal.return_type = parse_callable_return(child);
        } else {
            warn_unknown(element, child);
        }
    }

    if (found_inst_param) {
        LOG_ERRORV(element->GetLineNum(), "Signal '{}' takes instance parameter",
                   signal.name);
    }

    return signal;
}

VirtualMethod Parser::parse_virtual_method(const XMLElement* element)
{
    VirtualMethod method;

    auto parse_extra_attributes =
        [&](const XMLAttribute* attr, std::string_view attr_name) -> bool {
            if (attr_name == "invoker") {
                method.invoker = attr->Value();
                return true;
            } else {
                return false;
            }
        };
    method.func.detail.attributes =
        parse_callable_attributes(element, VIRTUAL_METHOD_ELEMENT,
                                  parse_extra_attributes);

    bool found_inst_param = false;
    for (const XMLElement* child = element->FirstChildElement(); child;
         child = child->NextSiblingElement()) {

        std::string_view name{child->Name()};

        if (!parse_function_elements(child, name, method.func, found_inst_param)) {
            warn_unknown(element, child);
        }
    }

    if (!found_inst_param) {
        LOG_ERRORV(element->GetLineNum(),
                   "Virtual method '{}' missing instance parameter",
                   method.func.detail.attributes.name);
    }

    return method;
}

CallableAttributes Parser::parse_callable_attributes(
    const XMLElement* element, std::string_view element_name,
    const ParseExtraAttributes& parse_extra_attributes)
{
    CallableAttributes parsed;

    constexpr const char* const NAME_ATTR = "name";
    populate_str_attr(element, NAME_ATTR, element_name, parsed.name);

    for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next()) {
        std::string_view attr_name{attr->Name()};

        if (attr_name == NAME_ATTR) {
            // Mandatory values already set
        } else if (parse_info_attributes(element, attr, attr_name, parsed.info_attributes)) {
            // Value set as side-effect
        } else if (attr_name == "c:identifier") {
            parsed.c_identifier = attr->Value();
        } else if (attr_name == "shadowed-by") {
            parsed.shadowed_by = attr->Value();
        } else if (attr_name == "shadows") {
            parsed.shadows = attr->Value();
        } else if (attr_name == "throws") {
            parsed.can_throw = parse_opt_bool(attr);
        } else if (attr_name == "moved-to") {
            parsed.moved_to = attr->Value();
        } else if (attr_name == "glib:async-func") {
            parsed.async_func = attr->Value();
        } else if (attr_name == "glib:sync-func") {
            parsed.sync_func = attr->Value();
        } else if (attr_name == "glib:finish-func") {
            parsed.finish_func = attr->Value();
        } else if (parse_extra_attributes(attr, attr_name)) {
            // Handled in caller function
        } else {
            warn_unknown(element, attr);
        }
    }

    return parsed;
}

bool Parser::parse_any_type(const XMLElement* element, std::string_view element_name,
                            AnyType& any_type)
{
    if (element_name == TYPE_ELEMENT) {
        any_type = parse_type(element);
        return true;
    } else if (element_name == ARRAY_ELEMENT) {
        any_type = parse_array_type(element);
        return true;
    }

    return false;
}

bool Parser::parse_doc_elements(const XMLElement* element, std::string_view element_name,
                                DocElements& doc_elements)
{
    if (element_name == DOC_ELEMENT) {
        doc_elements.doc = parse_doc(element);
        return true;
    } else if (element_name == SOURCE_POSITION_ELEMENT) {
        doc_elements.src_pos = SourcePosition{};
        for (const XMLAttribute* attr = element->FirstAttribute(); attr; attr = attr->Next())
        {
            parse_source_position(attr, attr->Name(), *doc_elements.src_pos);
        }
        return true;
    } else if (element_name == "doc-version" || element_name == "doc-stability"
               || element_name == "doc-deprecated") {
        if (m_warn_ignored) {
            fmt::println("WARN (line={}): Ignored child element '{}'",
                         element->GetLineNum(), element_name);
        }
        return true;
    } else {
        return false;
    }
}

bool Parser::parse_inline_function_elements(const XMLElement* element,
                                            std::string_view element_name,
                                            FunctionInline& function,
                                            bool& found_inst_param)
{
    if (parse_doc_elements(element, element_name, function.doc_elements)) {
        return true;
    } else if (element_name == CALLABLE_PARAMS_ELEMENT) {
        function.params = parse_callable_params(element, found_inst_param);
        return true;
    } else if (element_name == CALLABLE_RETURN_ELEMENT) {
        function.return_type = parse_callable_return(element);
        return true;
    } else {
        return false;
    }
}

bool Parser::parse_function_elements(const XMLElement* element,
                                     std::string_view element_name,
                                     Function& function,
                                     bool& found_inst_param)
{
    if (parse_inline_function_elements(element, element_name, function.detail,
                                       found_inst_param)) {
        return true;
    } else if (element_name == ANNOTATION_ELEMENT) {
        function.annotations.push_back(parse_annotation(element));
        return true;
    } else {
        return false;
    }
}

bool Parser::parse_source_position(const XMLAttribute* attr, std::string_view attr_name,
                                   SourcePosition& src_pos)
{
    if (attr_name == "filename") {
        src_pos.filename = attr->Value();
        return true;
    } else if (attr_name == "line") {
        src_pos.line = attr->IntValue();
        return true;
    } else if (attr_name == "column") {
        src_pos.column = attr->IntValue();
        return true;
    } else {
        return false;
    }
}

bool Parser::parse_info_attributes(const XMLElement* element, const XMLAttribute* attr,
                                   std::string_view attr_name, InfoAttributes& info)
{
    if (attr_name == "introspectable") {
        info.is_skippable = parse_introspectable_as_skippable(attr);
        return true;
    } else if (attr_name == "deprecated") {
        info.is_deprecated = parse_opt_bool(attr);
        return true;
    } else if (attr_name == "deprecated-version") {
        info.deprecated_version = attr->Value();
        return true;
    } else if (attr_name == "version") {
        info.version = attr->Value();
        return true;
    } else if (attr_name == "stability") {
        info.stability = parse_stability(attr);
        return true;
    }

    return false;
}

bool Parser::parse_info_elements(const XMLElement* element,
                                 std::string_view element_name, InfoElements& info)
{
    if (element_name == ANNOTATION_ELEMENT) {
        info.annotations.push_back(parse_annotation(element));
        return true;
    } else if (parse_doc_elements(element, element_name, info.doc_elements)) {
        return true;
    }

    return false;
}

bool Parser::populate_str_attr(const XMLElement* element, std::string_view attr,
                               std::string_view pod, std::string& dest)
{
    const char* value = element->Attribute(attr.data());
    if (!value) {
        LOG_ERRORV(element->GetLineNum(), "{} is missing {}", pod, attr);
        return false;
    } else {
        dest = value;
        return true;
    }
}

Repository load_repository_from_file(const ParseArgs& args)
{
    XMLDocument doc;
    if (doc.LoadFile(args.filepath.data()) != XML_SUCCESS) {
        throw GirParseError(doc.ErrorStr());
    }

    Parser parser(args);
    Repository repo = parser.parse_repo(doc);

    if (parser.has_errors()) {
        throw GirParseError("GIR has errors");
    }

    return repo;
}
