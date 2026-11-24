/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 */

package xlang.compiler.semantic

import xlang.SourceLocation
import xlang.compiler.parser.program.ImportDeclaration
import xlang.compiler.parser.program.Member
import xlang.compiler.parser.program.MemberRegistry
import xlang.compiler.parser.program.PackageDeclaration
import xlang.compiler.parser.program.PreprocessSetting
import xlang.compiler.parser.program.Struct
import xlang.lexer.Token
import xlang.util.ArrayList
import xlang.util.HashMap
import xlang.util.MapEntry
import xlang.util.string.String


private fun childNameEq(left: pointer<*>, right: pointer<*>) -> bool =
    String.streq(left as pointer<char>, right as pointer<char>)


/**
 * Represents a normalized view of a parsed program.
 *
 * <p>A {@code NormalizedProgram} stores the major top-level components produced
 * after program normalization: import declarations, package name, body
 * identity, and member registries classified by declaration kind.
 *
 * <p>The preprocessing-setting and import collections are normalized to empty
 * {@code ArrayList} instances when {@code null} values are supplied to the
 * constructor. Consumers can therefore access these collections without using
 * a separate null-list representation.
 *
 * <p>Package and structure declarations are consumed during construction to
 * fill the normalized package-name, body-name, and registry fields, but are not
 * stored afterward.
 *
 * <p>All non-null objects and collections supplied to the constructor are stored
 * directly and are not copied or cloned.
 */
struct NormalizedProgram
{
    /**
     * Indicates that the normalized program represents a {@code struct}
     * declaration body.
     */
    static val STRUCT_TYPE: int = 1

    /**
     * Indicates that the normalized program represents a {@code class}
     * declaration body.
     */
    static val CLASS_TYPE: int = 2

    /**
     * Indicates that the normalized program represents an {@code interface}
     * declaration body.
     */
    static val INTERFACE_TYPE: int = 3

    /**
     * Indicates that the normalized program represents an {@code annotation}
     * declaration body.
     */
    static val ANNOTATION_TYPE: int = 4


    /**
     * Creates a member registry containing only function members declared
     * in the specified struct body.
     *
     * <p>All members of the struct are traversed, and only members for which
     * {@code Member.isFunction()} returns {@code true} are added to the
     * resulting registry. Null members are ignored.</p>
     * 
     * <p>If {@code body} is {@code null}, an empty registry is returned.</p>
     *
     * @param body              the struct whose members should be inspected
     *
     * @return                  a new registry containing all function members of the struct,
     *                          or an empty registry if {@code body} is {@code null}
     */
    private static fun functionRegistryFrom(body: pointer<Struct>) -> pointer<MemberRegistry>
    {
        val result: pointer<ArrayList> = new ArrayList(sizeof(Member))

        if body == null:
            return new MemberRegistry(result)

        val members: pointer<ArrayList> = body.getMembers()

        for (var i = 0; i < members.length; i++):
        {
            val member: pointer<Member> = members.get(i) as pointer<Member>

            if member != null && member.isFunction():
                result.push(member)
        }

        return new MemberRegistry(result)
    }


    /**
     * Creates a member registry containing only field members declared
     * in the specified struct body.
     *
     * <p>All members of the struct are traversed, and only members for which
     * {@code Member.isField()} returns {@code true} are added to the
     * resulting registry. Null members are ignored.</p>
     *
     * <p>If {@code body} is {@code null}, an empty registry is returned.</p>
     *
     * @param body              the struct whose members should be inspected
     *
     * @return                  a new registry containing all field members of the struct,
     *                          or an empty registry if {@code body} is {@code null}
     */
    private static fun variableRegistryFrom(body: pointer<Struct>) -> pointer<MemberRegistry>
    {
        val result: pointer<ArrayList> = new ArrayList(sizeof(Member))

        if body == null:
            return new MemberRegistry(result)

        val members: pointer<ArrayList> = body.getMembers()

        for (var i = 0; i < members.length; i++):
        {
            val member: pointer<Member> = members.get(i) as pointer<Member>

            if member != null && member.isField():
                result.push(member)
        }

        return new MemberRegistry(result)
    }


    /**
     * Creates a member registry containing only struct constructor members
     * declared in the specified struct body.
     *
     * <p>All members of the struct are traversed, and only members for which
     * {@code Member.isStructConstructor()} returns {@code true} are added to
     * the resulting registry. Null members are ignored.</p>
     *
     * <p>If {@code body} is {@code null}, an empty registry is returned.</p>
     *
     * @param body              the struct whose members should be inspected
     *
     * @return                  a new registry containing all struct constructor members,
     *                          or an empty registry if {@code body} is {@code null}
     */
    private static fun constructorRegistryFrom(body: pointer<Struct>) -> pointer<MemberRegistry>
    {
        val result: pointer<ArrayList> = new ArrayList(sizeof(Member))

        if body == null:
            return new MemberRegistry(result)

        val members: pointer<ArrayList> = body.getMembers()

        for (var i = 0; i < members.length; i++):
        {
            val member: pointer<Member> = members.get(i) as pointer<Member>

            if member != null && member.isStructConstructor():
                result.push(member)
        }

        return new MemberRegistry(result)
    }


    /**
     * Creates a normalized program whose body is a structure declaration.
     *
     * @param preprocessSettings
     *                          a pointer to the preprocessing-setting collection,
     *                           or {@code null} to create an empty collection
     * @param packageDeclaration
     *                          a pointer to the package declaration, or
     *                          {@code null} if no package declaration is available
     * @param imports           a pointer to the import-declaration collection, or
     *                          {@code null} to create an empty collection
     * @param body              a pointer to the structure declaration, or
     *                          {@code null} if no structure body is available
     * @return                  a pointer to the newly created normalized program
     */
    static fun fromStruct(
        preprocessSettings: pointer<ArrayList>,
        packageDeclaration: pointer<PackageDeclaration>,
        imports: pointer<ArrayList>,
        body: pointer<Struct>
    ) -> pointer<NormalizedProgram>
    {
        val functionRegistry: pointer<MemberRegistry> = NormalizedProgram.functionRegistryFrom(body)
        val variableRegistry: pointer<MemberRegistry> = NormalizedProgram.variableRegistryFrom(body)
        val constructorRegistry: pointer<MemberRegistry> = NormalizedProgram.constructorRegistryFrom(body)
        val result: pointer<NormalizedProgram> = new NormalizedProgram(
            preprocessSettings,
            packageDeclaration,
            imports,
            STRUCT_TYPE,
            body,
            functionRegistry.getMembers(),
            variableRegistry.getMembers(),
            constructorRegistry.getMembers())

        result.bodyName = if body == null:
                null
            else:
                body.getStructName()

        return result
    }


    /**
     * Normalized package-name components for this program.
     *
     * <p>The representation matches {@code ImportAPI}: each item is a
     * {@code pointer<char>} slot stored inside an {@code ArrayList}.</p>
     */
    private var packageName: pointer<ArrayList>

    /**
     * The type of declaration body represented by this normalized program.
     */
    private var bodyType: int

    /**
     * Normalized declaration body name.
     *
     * <p>For a struct body, this is the struct name. A {@code null} value means
     * the body has no normalized name yet.</p>
     */
    private var bodyName: pointer<char>

    /**
     * Raw declaration body referenced by this normalized program.
     *
     * <p>The pointer is stored as an untyped host because different body kinds
     * use different concrete AST node types. For {@code STRUCT_TYPE}, the host
     * is expected to be a {@code pointer<Struct>}.</p>
     */
    private var host: pointer<*>

    /**
     * Registry containing function members declared by the body.
     */
    private var functionRegistry: pointer<MemberRegistry>

    /**
     * Registry containing variable-like members declared by the body.
     *
     * <p>Struct fields are treated as variables in the import API layer.</p>
     */
    private var variableRegistry: pointer<MemberRegistry>

    /**
     * Registry containing constructor members declared by the body.
     */
    private var constructorRegistry: pointer<MemberRegistry>

    /**
     * The ordered collection of preprocessing settings associated with the
     * normalized program.
     *
     * <p>If no preprocessing-setting collection is supplied during
     * construction, this field is initialized with a newly allocated empty
     * {@code ArrayList}.
     *
     * <p>When a non-null collection is supplied, that collection is stored
     * directly and is not copied or cloned.
     */
    private var preprocessSettings: pointer<ArrayList>

    /**
     * The ordered collection of import declarations associated with the
     * normalized program.
     *
     * <p>If no import collection is supplied during construction, this field is
     * initialized with a newly allocated empty {@code ArrayList}.
     *
     * <p>When a non-null collection is supplied, that collection is stored
     * directly and is not copied or cloned.
     */
    private var imports: pointer<ArrayList>

    /**
     * Stores the normalized program that owns this nested program.
     *
     * <p>A null value indicates that this program is top-level or has not yet
     * been attached to a parent program.</p>
     */
    private var parrent: pointer<NormalizedProgram>

    /**
     * Stores child programs by body name.
     *
     * <p>The map is created lazily when the first valid child is added.</p>
     */
    private var children: pointer<HashMap>


    /**
     * Creates a normalized program from the specified top-level program
     * components.
     *
     * <p>If {@code preprocessSettings} is {@code null}, a new empty
     * {@code ArrayList} capable of storing {@code PreprocessSetting} entries is
     * allocated. Otherwise, the supplied collection is stored directly and is
     * not copied or cloned.
     *
     * <p>The supplied package declaration is consumed immediately to derive the
     * normalized package name. It is not stored afterward.
     *
     * <p>If {@code imports} is {@code null}, a new empty {@code ArrayList}
     * capable of storing {@code ImportDeclaration} entries is allocated.
     * Otherwise, the supplied import collection is stored directly and is not
     * copied or cloned.
     *
     * <p>The supplied member lists are consumed immediately to build the
     * normalized member registries. The lists themselves are stored inside
     * those registries.
     *
     * @param preprocessSettings
     *                          a pointer to the preprocessing-setting
     *                          collection, or {@code null} to create an empty
     *                          collection
     * @param packageDeclaration
     *                          a pointer to the package declaration, or
     *                          {@code null} if no package declaration is
     *                          available
     * @param imports           a pointer to the import-declaration collection,
     *                          or {@code null} to create an empty collection
     * @param bodyType          the type of declaration body
     * @param host              a pointer to the raw declaration body
     * @param functionMembers   a pointer to the normalized function-member list
     * @param variableMembers   a pointer to the normalized variable-member list
     * @param constructorMembers
     *                          a pointer to the normalized constructor-member list
     */
    private constructor(
        preprocessSettings: pointer<ArrayList>,
        packageDeclaration: pointer<PackageDeclaration>,
        imports: pointer<ArrayList>,
        bodyType: int,
        host: pointer<*>,
        functionMembers: pointer<ArrayList>,
        variableMembers: pointer<ArrayList>,
        constructorMembers: pointer<ArrayList>
    )
    {
        this.preprocessSettings = if preprocessSettings == null:
                new ArrayList(sizeof(PreprocessSetting))
            else:
                preprocessSettings

        this.packageName = if packageDeclaration == null:
                new ArrayList(sizeof(pointer<char>))
            else:
                packageDeclaration.getQualifiedName()

        this.imports = if imports == null:
                new ArrayList(sizeof(ImportDeclaration))
            else:
                imports

        this.bodyType = bodyType
        this.bodyName = null
        this.host = host
        this.functionRegistry = new MemberRegistry(functionMembers)
        this.variableRegistry = new MemberRegistry(variableMembers)
        this.constructorRegistry = new MemberRegistry(constructorMembers)
        this.children = null
        this.parrent = null
    }


    /**
     * Sets the normalized program that owns this program.
     *
     * @param parent            the parent program, or null to detach this
     *                          program
     * @return                  this normalized program
     */
    fun setParent(parent: pointer<NormalizedProgram>) -> pointer<NormalizedProgram>
    {
        this.parrent = parent
        return this
    }


    /**
     * Returns the normalized program that owns this program.
     *
     * @return                  the parent program, or null when this program is
     *                          top-level or detached
     */
    fun getParrent() -> pointer<NormalizedProgram> = this.parrent


    /**
     * Adds a child program using its body name as the key.
     *
     * <p>A null child or a child without a body name is ignored. Adding another
     * child with the same name replaces the previously stored child.</p>
     *
     * @param child             the child program to add
     * @return                  this normalized program
     */
    fun addChild(child: pointer<NormalizedProgram>) -> pointer<NormalizedProgram>
    {
        if child == null || child.getBodyName() == null:
            return this

        if this.children == null:
            this.children = new HashMap(childNameEq, String.strHash)

        this.children.put(child.getBodyName(), child)
        return this
    }


    /**
     * Returns the child program associated with the specified body name.
     *
     * @param name              the child body name
     * @return                  the matching child, or null when it is absent
     */
    fun getChild(name: pointer<char>) -> pointer<NormalizedProgram> =
        if name == null || this.children == null:
            null
        else:
            this.children.get(name) as pointer<NormalizedProgram>


    /**
     * Tests whether a child with the specified body name is present.
     *
     * @param name              the child body name
     * @return                  true when the child exists
     */
    fun hasChild(name: pointer<char>) -> bool =
        name != null && this.children != null && this.children.containsKey(name)


    /**
     * Returns all child programs in a new list.
     *
     * @return                  a list of child programs, or an empty list when
     *                          no children have been added
     */
    fun getChildren() -> pointer<ArrayList>
    {
        val result: pointer<ArrayList> = new ArrayList(sizeof(NormalizedProgram))

        if this.children == null:
            return result

        val entries: pointer<ArrayList> = this.children.getEntries()

        for (var i: int = 0; i < entries.length; i++):
        {
            val entry: pointer<MapEntry> = entries.get(i) as pointer<MapEntry>

            if entry != null && entry.value != null:
                result.push(entry.value)
        }

        return result
    }


    /**
     * Builds and returns the fully qualified path of the current declaration.
     *
     * <p>The returned path is composed of the qualified package name, if a
     * package declaration is present, followed by the name of the declaration
     * body when the body has a valid name.</p>
     *
     * <p>If no package declaration exists, a new empty {@link ArrayList} is
     * created and used as the base path. When the current body represents a
     * struct, its struct name is appended to the end of the path.</p>
     *
     * <p>For example, a struct named {@code Example} declared inside the package
     * {@code foo.bar} produces a path equivalent to:</p>
     *
     * <pre>
     * ["foo", "bar", "Example"]
     * </pre>
     *
     * @return                  a list containing the components of the fully qualified path;
     *                          never {@code null}
     */
    fun getFullpath() -> pointer<ArrayList>
    {
        val result: pointer<ArrayList> = if this.packageName == null:
                new ArrayList(sizeof(pointer<char>))
            else:
                this.packageName.clone()

        if this.bodyName != null:
            result.push(this.bodyName.ref)

        return result
    }


    /**
     * Returns the name associated with the current declaration body.
     *
     * <p>Currently, only struct bodies provide a body name. The name is
     * computed during construction and stored in the normalized body-name
     * field.</p>
     *
     * <p>If the body does not represent a struct, or if no body has been assigned,
     * this function returns {@code null}.</p>
     *
     * @return                  the name of the current struct body, or {@code null} if the current
     *                          body has no applicable name
     */
    fun getBodyName() -> pointer<char> = this.bodyName


    /**
     * Returns normalized package-name components.
     */
    fun getPackageName() -> pointer<ArrayList> = this.packageName


    /**
     * Returns the normalized body type.
     */
    fun getBodyType() -> int = this.bodyType


    /**
     * Returns the raw declaration body referenced by this normalized program.
     *
     * <p>The returned pointer is intentionally untyped. Callers should inspect
     * {@code getBodyType()} before casting it to a concrete AST node type.</p>
     *
     * @return                  the raw declaration body pointer, or {@code null}
     *                          if no body is associated with this program
     */
    fun getHost() -> pointer<*> = this.host


    /**
     * Returns the source range occupied by this program's declaration name.
     *
     * <p>The current implementation locates the name token stored by the
     * original structure declaration. The returned range therefore points at
     * the declared type name rather than at the complete declaration.</p>
     *
     * @return                  the declaration-name location, or null when the
     *                          original declaration does not expose one
     */
    fun getSourceLocation() -> pointer<SourceLocation>
    {
        if this.bodyType != STRUCT_TYPE || this.host == null || this.bodyName == null:
            return null

        val body: pointer<Struct> = this.host as pointer<Struct>
        val tokens: pointer<ArrayList> = body.getExtraTokens()

        for (var i: int = 0; i < tokens.length; i++):
        {
            val token: pointer<Token> = tokens.get(i) as pointer<Token>

            if token != null && token.pos != null &&
                String.streq(token.text, this.bodyName):
                return new SourceLocation(
                    null,
                    token.pos.offset,
                    token.pos.line,
                    token.pos.column,
                    token.pos.length)
        }

        return null
    }


    /**
     * Returns the registry containing function members.
     */
    fun getFunctionRegistry() -> pointer<MemberRegistry> = this.functionRegistry


    /**
     * Returns the registry containing variable-like members.
     */
    fun getVariableRegistry() -> pointer<MemberRegistry> = this.variableRegistry


    /**
     * Returns the registry containing constructor members.
     */
    fun getConstructorRegistry() -> pointer<MemberRegistry> = this.constructorRegistry


    /**
     * Returns the preprocessing-setting collection associated with this
     * normalized program.
     *
     * <p>The returned pointer refers directly to the internally stored
     * {@code ArrayList}. The collection is not copied or cloned.
     *
     * <p>Because the constructor normalizes a {@code null} preprocessing-setting
     * collection to an empty list, this method normally returns a valid
     * {@code ArrayList}.
     *
     * <p>Modifications performed through the returned list affect the same
     * preprocessing-setting collection referenced internally by this
     * {@code NormalizedProgram}.
     *
     * @return                  a pointer to the internally stored
     *                          preprocessing-setting collection
     */
    fun getPreprocessSettings() -> pointer<ArrayList> = this.preprocessSettings


    /**
     * Reconstructs a package declaration from the normalized package name.
     *
     * <p>The original package declaration is not stored. This compatibility
     * accessor exists for the current normalizer code and should be replaced by
     * direct {@link #getPackageName()} usage.</p>
     *
     * @return                  a new package declaration backed by a clone of
     *                          the normalized package-name component list
     */
    fun getPackageDeclaration() -> pointer<PackageDeclaration> =
        if this.packageName == null:
            null
        else:
            new PackageDeclaration(this.packageName.clone())


    /**
     * Returns the import-declaration collection associated with this normalized
     * program.
     *
     * <p>The returned pointer refers directly to the internally stored
     * {@code ArrayList}. The collection is not copied or cloned.
     *
     * <p>Because the constructor normalizes a {@code null} import collection to
     * an empty list, this method normally returns a valid {@code ArrayList}.
     *
     * <p>Modifications performed through the returned list affect the same
     * import collection referenced internally by this
     * {@code NormalizedProgram}.
     *
     * @return                  a pointer to the internally stored
     *                          import-declaration collection
     */
    fun getImports() -> pointer<ArrayList> = this.imports
}
