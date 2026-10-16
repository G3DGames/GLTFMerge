//** @abstract(Removes objects from a glTF object tree, renumbering every reference to the
//** objects that follow.)
//**
//** glTF objects refer to each other by index, so deleting one means every later index
//** moves down by one. @link(TglTFEdit) does that bookkeeping for the references it knows:
//** those in the glTF 2.0 core schema, and the texture and image references of material and
//** texture extensions. It deletes accessors, bufferViews, buffers, animations, nodes, and,
//** through @link(TglTFEdit.DeleteUnusedObjects), meshes, skins, materials, textures, images
//** and samplers. Extensions that keep other indices in their own JSON cannot be renumbered,
//** so the operations that would break them refuse to run when the tree uses one, and say
//** so.
//**
//** Removing a bufferView also cuts its bytes out of the buffer's Data, so the space is
//** reclaimed. Only bytes no other bufferView uses are cut, always in a multiple of 4 so
//** that the data after it keeps its alignment.
//**
//** Works on any @code(TglTF), typically the document's own tree or the copy made for a
//** save. Not thread-safe.
unit glTF.Edit;

{
  Removes objects from a glTF object tree, renumbering every reference to the
  objects that follow.

  glTF objects refer to each other by index, so deleting one means every later
  index moves down by one. TglTFEdit does that bookkeeping for the references
  it knows: those in the glTF 2.0 core schema, and the texture and image
  references of material and texture extensions. It deletes accessors,
  bufferViews, buffers, animations, nodes, and, through DeleteUnusedObjects,
  meshes, skins, materials, textures, images and samplers. Extensions that
  keep other indices in their own JSON cannot be renumbered, so the operations
  that would break them refuse to run when the tree uses one, and say so.

  Removing a bufferView also cuts its bytes out of the buffer's Data, so the
  space is reclaimed. Only bytes no other bufferView uses are cut, always in a
  multiple of 4 so that the data after it keeps its alignment.

  Works on any TglTF, typically the document's own tree or the copy made for a
  save. Not thread-safe.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections,
  System.Generics.Defaults,

  glTF.Base,
  glTF.Classes;

type
  //** @abstract(Editing operations on a glTF object tree that keep its indices consistent.)
  //**
  //** All methods are class methods; there is nothing to create. A Delete method assumes
  //** the object it deletes is no longer referred to: use the matching IsUsed method, or
  //** @link(DeleteUnusedData), which checks.
  //**
  //** @longCode(#
  //** // Drop animation 2 and whatever data only it used
  //** TglTFEdit.DeleteAnimation(Doc.Root, 2, Warnings);
  //** #)
  /// <summary>Editing operations on a glTF object tree that keep its indices
  /// consistent.</summary>
  /// <remarks>All methods are class methods; there is nothing to create. A Delete method
  /// assumes the object it deletes is no longer referred to: use the matching IsUsed method,
  /// or <see cref="DeleteUnusedData"/>, which checks.</remarks>
  /// <example><code>
  /// // Drop animation 2 and whatever data only it used
  /// TglTFEdit.DeleteAnimation(Doc.Root, 2, Warnings);
  /// </code></example>
  TglTFEdit = class
  public
    //** @abstract(Tells whether the tree uses an extension that refers to bufferViews or
    //** buffers from its own JSON.)
    //**
    //** These are KHR_draco_mesh_compression, EXT_meshopt_compression and
    //** KHR_meshopt_compression. While one is used, bufferViews and buffers must not be
    //** deleted, as the extension's indices would then point at the wrong data.
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @param(AName The first such extension found; empty when none.)
    //**
    //** @returns(True when such an extension is in @code(ExtensionsUsed).)
    /// <summary>Tells whether the tree uses an extension that refers to bufferViews or buffers
    /// from its own JSON.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <param name="AName">The first such extension found; empty when none.</param>
    /// <returns>True when such an extension is in <c>ExtensionsUsed</c>.</returns>
    /// <remarks>These are KHR_draco_mesh_compression, EXT_meshopt_compression and
    /// KHR_meshopt_compression. While one is used, bufferViews and buffers must not be
    /// deleted, as the extension's indices would then point at the wrong data.</remarks>
    class function UsesBufferViewExtension(ARoot: TglTF; out AName: string): Boolean; static;

    //** @abstract(Tells whether the tree uses an extension that refers to accessors from its
    //** own JSON.)
    //**
    //** This is EXT_mesh_gpu_instancing. While it is used, accessors must not be deleted.
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @param(AName The first such extension found; empty when none.)
    //**
    //** @returns(True when such an extension is in @code(ExtensionsUsed).)
    /// <summary>Tells whether the tree uses an extension that refers to accessors from its own
    /// JSON.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <param name="AName">The first such extension found; empty when none.</param>
    /// <returns>True when such an extension is in <c>ExtensionsUsed</c>.</returns>
    /// <remarks>This is EXT_mesh_gpu_instancing. While it is used, accessors must not be
    /// deleted.</remarks>
    class function UsesAccessorExtension(ARoot: TglTF; out AName: string): Boolean; static;

    //** @abstract(Tells whether anything in the tree refers to an accessor.)
    //**
    //** Checks mesh primitive attributes, indices and morph targets, skin inverse bind
    //** matrices and animation sampler inputs and outputs.
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @param(AIndex Index in @code(ARoot.Accessors).)
    //**
    //** @returns(True when at least one reference was found.)
    /// <summary>Tells whether anything in the tree refers to an accessor.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <param name="AIndex">Index in <c>ARoot.Accessors</c>.</param>
    /// <returns>True when at least one reference was found.</returns>
    /// <remarks>Checks mesh primitive attributes, indices and morph targets, skin inverse bind
    /// matrices and animation sampler inputs and outputs.</remarks>
    class function IsAccessorUsed(ARoot: TglTF; AIndex: Integer): Boolean; static;

    //** @abstract(Tells whether anything in the tree refers to a bufferView.)
    //**
    //** Checks accessors, their sparse indices and values, and images.
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @param(AIndex Index in @code(ARoot.BufferViews).)
    //**
    //** @returns(True when at least one reference was found.)
    /// <summary>Tells whether anything in the tree refers to a bufferView.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <param name="AIndex">Index in <c>ARoot.BufferViews</c>.</param>
    /// <returns>True when at least one reference was found.</returns>
    /// <remarks>Checks accessors, their sparse indices and values, and images.</remarks>
    class function IsBufferViewUsed(ARoot: TglTF; AIndex: Integer): Boolean; static;

    //** @abstract(Tells whether any bufferView refers to a buffer.)
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @param(AIndex Index in @code(ARoot.Buffers).)
    //**
    //** @returns(True when at least one bufferView is in that buffer.)
    /// <summary>Tells whether any bufferView refers to a buffer.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <param name="AIndex">Index in <c>ARoot.Buffers</c>.</param>
    /// <returns>True when at least one bufferView is in that buffer.</returns>
    class function IsBufferUsed(ARoot: TglTF; AIndex: Integer): Boolean; static;

    //** @abstract(Deletes an accessor and renumbers the references to the accessors after it.)
    //**
    //** Nothing may still refer to the accessor itself. Its bufferViews are left in place.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndex Index in @code(ARoot.Accessors).)
    /// <summary>Deletes an accessor and renumbers the references to the accessors after
    /// it.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndex">Index in <c>ARoot.Accessors</c>.</param>
    /// <remarks>Nothing may still refer to the accessor itself. Its bufferViews are left in
    /// place.</remarks>
    class procedure DeleteAccessor(ARoot: TglTF; AIndex: Integer); static;

    //** @abstract(Deletes a bufferView, cuts its bytes out of its buffer and renumbers the
    //** references to the bufferViews after it.)
    //**
    //** The bytes cut are the view rounded up to 4 bytes, so its padding goes too, or rounded
    //** down when another view uses the padding; nothing is cut when another view overlaps
    //** it. The views after it in the same buffer move down by the amount cut, which is a
    //** multiple of 4 unless the view is at the end of the buffer. The buffer's Data is
    //** replaced by a new array, so an array shared with another tree is not changed.
    //** Nothing may still refer to the bufferView itself.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndex Index in @code(ARoot.BufferViews).)
    /// <summary>Deletes a bufferView, cuts its bytes out of its buffer and renumbers the
    /// references to the bufferViews after it.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndex">Index in <c>ARoot.BufferViews</c>.</param>
    /// <remarks>The bytes cut are the view rounded up to 4 bytes, so its padding goes too, or
    /// rounded down when another view uses the padding; nothing is cut when another view
    /// overlaps it. The views after it in the same buffer move down by the amount cut, which is
    /// a multiple of 4 unless the view is at the end of the buffer. The buffer's Data is
    /// replaced by a new array, so an array shared with another tree is not changed. Nothing
    /// may still refer to the bufferView itself.</remarks>
    class procedure DeleteBufferView(ARoot: TglTF; AIndex: Integer); static;

    //** @abstract(Deletes several accessors at once and renumbers every reference to the
    //** others.)
    //**
    //** Much faster than deleting them one by one: the references are renumbered in one
    //** pass. Nothing may still refer to the accessors deleted. Their bufferViews are left in
    //** place.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndices Indices in @code(ARoot.Accessors), in any order; repeats and invalid
    //** indices are ignored.)
    /// <summary>Deletes several accessors at once and renumbers every reference to the
    /// others.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndices">Indices in <c>ARoot.Accessors</c>, in any order; repeats and
    /// invalid indices are ignored.</param>
    /// <remarks>Much faster than deleting them one by one: the references are renumbered in
    /// one pass. Nothing may still refer to the accessors deleted. Their bufferViews are left
    /// in place.</remarks>
    class procedure DeleteAccessors(ARoot: TglTF; const AIndices: TArray<Integer>); static;

    //** @abstract(Deletes several bufferViews at once, cutting their bytes out of their
    //** buffers.)
    //**
    //** The same rules as DeleteBufferView, applied to all of them together: each buffer is
    //** rebuilt once, without the bytes cut, and the references to the remaining views are
    //** renumbered in one pass. Bytes a remaining view uses are never cut. Nothing may still
    //** refer to the views deleted.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndices Indices in @code(ARoot.BufferViews), in any order; repeats and
    //** invalid indices are ignored.)
    /// <summary>Deletes several bufferViews at once, cutting their bytes out of their
    /// buffers.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndices">Indices in <c>ARoot.BufferViews</c>, in any order; repeats and
    /// invalid indices are ignored.</param>
    /// <remarks>The same rules as DeleteBufferView, applied to all of them together: each
    /// buffer is rebuilt once, without the bytes cut, and the references to the remaining
    /// views are renumbered in one pass. Bytes a remaining view uses are never cut. Nothing
    /// may still refer to the views deleted.</remarks>
    class procedure DeleteBufferViews(ARoot: TglTF; const AIndices: TArray<Integer>); static;

    //** @abstract(Deletes a buffer and renumbers the bufferViews that refer to the buffers
    //** after it.)
    //**
    //** No bufferView may still be in the buffer itself.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndex Index in @code(ARoot.Buffers).)
    /// <summary>Deletes a buffer and renumbers the bufferViews that refer to the buffers after
    /// it.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndex">Index in <c>ARoot.Buffers</c>.</param>
    /// <remarks>No bufferView may still be in the buffer itself.</remarks>
    class procedure DeleteBuffer(ARoot: TglTF; AIndex: Integer); static;

    //** @abstract(Deletes those of the given accessors that nothing uses any more, then the
    //** bufferViews and buffers that only they used.)
    //**
    //** Only the listed accessors and the bufferViews and buffers they lead to are
    //** considered, so data the file never used is left alone. Up to 3 zero bytes of padding
    //** left at the end of a buffer that was cut are removed too. A buffer is deleted when
    //** its data was cut down to nothing. When the tree uses an extension that would be
    //** broken, the step concerned is skipped and a warning added.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AAccessors Indices in @code(ARoot.Accessors) that may have become unused; may
    //** repeat and may include indices that are still used.)
    //**
    //** @param(AWarnings Receives a line for each step skipped; may be nil.)
    //**
    //** @returns(The number of accessors deleted.)
    /// <summary>Deletes those of the given accessors that nothing uses any more, then the
    /// bufferViews and buffers that only they used.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AAccessors">Indices in <c>ARoot.Accessors</c> that may have become unused;
    /// may repeat and may include indices that are still used.</param>
    /// <param name="AWarnings">Receives a line for each step skipped; may be nil.</param>
    /// <returns>The number of accessors deleted.</returns>
    /// <remarks>Only the listed accessors and the bufferViews and buffers they lead to are
    /// considered, so data the file never used is left alone. Up to 3 zero bytes of padding
    /// left at the end of a buffer that was cut are removed too. A buffer is deleted when its
    /// data was cut down to nothing. When the tree uses an extension that would be
    /// broken, the step concerned is skipped and a warning added.</remarks>
    class function DeleteUnusedData(ARoot: TglTF; const AAccessors: TArray<Integer>;
      AWarnings: TStrings): Integer; static;

    //** @abstract(Returns the accessors an animation's samplers use.)
    //**
    //** @param(AAnimation The animation.)
    //**
    //** @returns(The input and output accessor indices, each once, in sampler order.)
    /// <summary>Returns the accessors an animation's samplers use.</summary>
    /// <param name="AAnimation">The animation.</param>
    /// <returns>The input and output accessor indices, each once, in sampler order.</returns>
    class function AnimationAccessors(AAnimation: TglTFAnimation): TArray<Integer>; static;

    //** @abstract(Deletes an animation and the data only it used.)
    //**
    //** Nothing in the glTF core schema refers to an animation by index, so no other index
    //** changes apart from those of the data deleted; see @link(DeleteUnusedData).
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndex Index in @code(ARoot.Animations).)
    //**
    //** @param(AWarnings Receives a line for each step skipped; may be nil.)
    /// <summary>Deletes an animation and the data only it used.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndex">Index in <c>ARoot.Animations</c>.</param>
    /// <param name="AWarnings">Receives a line for each step skipped; may be nil.</param>
    /// <remarks>Nothing in the glTF core schema refers to an animation by index, so no other
    /// index changes apart from those of the data deleted; see
    /// <see cref="DeleteUnusedData"/>.</remarks>
    class procedure DeleteAnimation(ARoot: TglTF; AIndex: Integer; AWarnings: TStrings); static;

    //** @abstract(Deletes every animation and the data only they used.)
    //**
    //** Accessors, bufferViews and buffer bytes that something else, such as a mesh or a
    //** skin, also uses are kept; see @link(DeleteUnusedData).
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AWarnings Receives a line for each step skipped; may be nil.)
    //**
    //** @returns(The number of animations deleted.)
    /// <summary>Deletes every animation and the data only they used.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AWarnings">Receives a line for each step skipped; may be nil.</param>
    /// <returns>The number of animations deleted.</returns>
    /// <remarks>Accessors, bufferViews and buffer bytes that something else, such as a mesh or
    /// a skin, also uses are kept; see <see cref="DeleteUnusedData"/>.</remarks>
    class function ClearAnimations(ARoot: TglTF; AWarnings: TStrings): Integer; static;

    //** @abstract(Tells whether two names are the same name, as duplicate checks see it.)
    //**
    //** Case is ignored, in every alphabet, and so are spaces at either end. Every duplicate
    //** check on names uses this, so that names differing only in case cannot both be used.
    //**
    //** @param(A A name.)
    //**
    //** @param(B Another name.)
    //**
    //** @returns(True when they are the same name.)
    /// <summary>Tells whether two names are the same name, as duplicate checks see
    /// it.</summary>
    /// <param name="A">A name.</param>
    /// <param name="B">Another name.</param>
    /// <returns>True when they are the same name.</returns>
    /// <remarks>Case is ignored, in every alphabet, and so are spaces at either end. Every
    /// duplicate check on names uses this, so that names differing only in case cannot both be
    /// used.</remarks>
    class function SameName(const A, B: string): Boolean; static;

    //** @abstract(Finds the animation with a name, case ignored.)
    //**
    //** @param(ARoot The tree to search.)
    //**
    //** @param(AName The name; an empty one is never found.)
    //**
    //** @param(AExcept An animation to skip, such as the one being renamed; -1 for none.)
    //**
    //** @returns(Index in @code(ARoot.Animations), or -1 when no other animation has the
    //** name.)
    /// <summary>Finds the animation with a name, case ignored.</summary>
    /// <param name="ARoot">The tree to search.</param>
    /// <param name="AName">The name; an empty one is never found.</param>
    /// <param name="AExcept">An animation to skip, such as the one being renamed; -1 for
    /// none.</param>
    /// <returns>Index in <c>ARoot.Animations</c>, or -1 when no other animation has the
    /// name.</returns>
    class function FindAnimation(ARoot: TglTF; const AName: string;
      AExcept: Integer = -1): Integer; static;

    //** @abstract(Tells why a name cannot be given to an animation.)
    //**
    //** @param(ARoot The tree holding the animations.)
    //**
    //** @param(AName The name wanted.)
    //**
    //** @param(AExcept The animation that is to get the name, which may already have it in
    //** another case; -1 for a new animation.)
    //**
    //** @returns(The reason, or an empty string when the name can be used: it is not empty and
    //** no other animation has it, case ignored.)
    /// <summary>Tells why a name cannot be given to an animation.</summary>
    /// <param name="ARoot">The tree holding the animations.</param>
    /// <param name="AName">The name wanted.</param>
    /// <param name="AExcept">The animation that is to get the name, which may already have it
    /// in another case; -1 for a new animation.</param>
    /// <returns>The reason, or an empty string when the name can be used: it is not empty and
    /// no other animation has it, case ignored.</returns>
    class function AnimationNameProblem(ARoot: TglTF; const AName: string;
      AExcept: Integer = -1): string; static;

    //** @abstract(Renames an animation, when the name passes AnimationNameProblem.)
    //**
    //** @param(ARoot The tree holding the animation.)
    //**
    //** @param(AIndex Index in @code(ARoot.Animations).)
    //**
    //** @param(AName The new name; spaces at either end are removed.)
    //**
    //** @returns(An empty string when renamed; otherwise why not, and nothing is changed.)
    /// <summary>Renames an animation, when the name passes AnimationNameProblem.</summary>
    /// <param name="ARoot">The tree holding the animation.</param>
    /// <param name="AIndex">Index in <c>ARoot.Animations</c>.</param>
    /// <param name="AName">The new name; spaces at either end are removed.</param>
    /// <returns>An empty string when renamed; otherwise why not, and nothing is
    /// changed.</returns>
    class function RenameAnimation(ARoot: TglTF; AIndex: Integer;
      const AName: string): string; static;

    //** @abstract(Returns the buffer new binary data should be appended to, creating one when
    //** needed.)
    //**
    //** That is buffers[0] when its data is loaded, so that a GLB keeps a single BIN chunk.
    //** Otherwise a new, empty buffer is added at the end; it has no uri, so a save decides
    //** where it goes.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @returns(Index in @code(ARoot.Buffers).)
    /// <summary>Returns the buffer new binary data should be appended to, creating one when
    /// needed.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <returns>Index in <c>ARoot.Buffers</c>.</returns>
    /// <remarks>That is buffers[0] when its data is loaded, so that a GLB keeps a single BIN
    /// chunk. Otherwise a new, empty buffer is added at the end; it has no uri, so a save
    /// decides where it goes.</remarks>
    class function DataBuffer(ARoot: TglTF): Integer; static;

    //** @abstract(Appends bytes to a buffer, starting on a 4-byte boundary.)
    //**
    //** The buffer is padded with zeros up to the boundary first. Its Data is replaced by a
    //** new array and its ByteLength updated.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(ABufferIndex Index in @code(ARoot.Buffers); its data must be loaded unless it
    //** is empty.)
    //**
    //** @param(AData The bytes to append.)
    //**
    //** @returns(The byte offset in the buffer where the bytes start.)
    //**
    //** @raises(EglTFError The buffer's data is not loaded.)
    /// <summary>Appends bytes to a buffer, starting on a 4-byte boundary.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="ABufferIndex">Index in <c>ARoot.Buffers</c>; its data must be loaded unless
    /// it is empty.</param>
    /// <param name="AData">The bytes to append.</param>
    /// <returns>The byte offset in the buffer where the bytes start.</returns>
    /// <exception cref="EglTFError">The buffer's data is not loaded.</exception>
    /// <remarks>The buffer is padded with zeros up to the boundary first. Its Data is replaced
    /// by a new array and its ByteLength updated.</remarks>
    class function AppendBufferData(ARoot: TglTF; ABufferIndex: Integer;
      const AData: TBytes): Int64; static;

    //** @abstract(Adds a name to @code(ExtensionsUsed) unless it is already there.)
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AName The extension name, for example KHR_texture_transform.)
    /// <summary>Adds a name to <c>ExtensionsUsed</c> unless it is already there.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AName">The extension name, for example KHR_texture_transform.</param>
    class procedure AddExtensionUsed(ARoot: TglTF; const AName: string); static;

    //** @abstract(Tells whether any node refers to a mesh.)
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @param(AIndex Index in @code(ARoot.Meshes).)
    //**
    //** @returns(True when at least one node has it as its mesh.)
    /// <summary>Tells whether any node refers to a mesh.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <param name="AIndex">Index in <c>ARoot.Meshes</c>.</param>
    /// <returns>True when at least one node has it as its mesh.</returns>
    class function IsMeshUsed(ARoot: TglTF; AIndex: Integer): Boolean; static;

    //** @abstract(Tells whether any node refers to a skin.)
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @param(AIndex Index in @code(ARoot.Skins).)
    //**
    //** @returns(True when at least one node has it as its skin.)
    /// <summary>Tells whether any node refers to a skin.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <param name="AIndex">Index in <c>ARoot.Skins</c>.</param>
    /// <returns>True when at least one node has it as its skin.</returns>
    class function IsSkinUsed(ARoot: TglTF; AIndex: Integer): Boolean; static;

    //** @abstract(Deletes nodes and renumbers every reference to the nodes after them.)
    //**
    //** The children of a deleted node that stay take its place: in its parent's children, or
    //** among the root nodes of the scenes it was in. Animation channels that target a deleted
    //** node are removed, and an animation left without channels is deleted with the data only
    //** it used. A deleted node that was a skin's "skeleton" leaves that skin without one. The
    //** meshes, skins and cameras of the deleted nodes stay; see @link(DeleteUnusedObjects).
    //**
    //** Only the glTF 2.0 core references are renumbered; an extension that refers to nodes
    //** from its own JSON is not.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AIndices Indices in @code(ARoot.Nodes), in any order; repeats and invalid indices
    //** are ignored.)
    //**
    //** @param(AWarnings Receives a line for each step skipped; may be nil.)
    //**
    //** @raises(EglTFError A node to delete is a joint of a skin; nothing is changed.)
    /// <summary>Deletes nodes and renumbers every reference to the nodes after them.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AIndices">Indices in <c>ARoot.Nodes</c>, in any order; repeats and invalid
    /// indices are ignored.</param>
    /// <param name="AWarnings">Receives a line for each step skipped; may be nil.</param>
    /// <exception cref="EglTFError">A node to delete is a joint of a skin; nothing is
    /// changed.</exception>
    /// <remarks>The children of a deleted node that stay take its place: in its parent's
    /// children, or among the root nodes of the scenes it was in. Animation channels that target
    /// a deleted node are removed, and an animation left without channels is deleted with the
    /// data only it used. A deleted node that was a skin's "skeleton" leaves that skin without
    /// one. The meshes, skins and cameras of the deleted nodes stay; see
    /// <see cref="DeleteUnusedObjects"/>. Only the glTF 2.0 core references are renumbered; an
    /// extension that refers to nodes from its own JSON is not.</remarks>
    class procedure DeleteNodes(ARoot: TglTF; const AIndices: TArray<Integer>;
      AWarnings: TStrings); static;

    //** @abstract(Deletes those of the given meshes, skins and materials that nothing uses any
    //** more, then everything that only they used.)
    //**
    //** Works down from the objects given: meshes no node uses, skins no node uses, and
    //** materials no primitive uses are deleted; then the textures only the deleted materials
    //** used, the images and samplers only those textures used, and the accessors,
    //** bufferViews and buffer bytes only all of these used @(see @link(DeleteUnusedData)@).
    //** Every reference to the objects that follow is renumbered, texture references in
    //** material extensions and image references in texture extensions included. Objects the
    //** file never used are left alone, as only what the given objects lead to is considered.
    //**
    //** Materials are kept when the tree uses KHR_materials_variants, which refers to them
    //** from its own JSON; a warning says so.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AMeshes Indices in @code(ARoot.Meshes) that may have become unused.)
    //**
    //** @param(ASkins Indices in @code(ARoot.Skins) that may have become unused.)
    //**
    //** @param(AMaterials Indices in @code(ARoot.Materials) that may have become unused.)
    //**
    //** @param(AAccessors Further indices in @code(ARoot.Accessors) that may have become
    //** unused.)
    //**
    //** @param(AWarnings Receives a line for each step skipped; may be nil.)
    //**
    //** @returns(The number of meshes, skins, materials, textures, images and samplers
    //** deleted.)
    /// <summary>Deletes those of the given meshes, skins and materials that nothing uses any
    /// more, then everything that only they used.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AMeshes">Indices in <c>ARoot.Meshes</c> that may have become
    /// unused.</param>
    /// <param name="ASkins">Indices in <c>ARoot.Skins</c> that may have become unused.</param>
    /// <param name="AMaterials">Indices in <c>ARoot.Materials</c> that may have become
    /// unused.</param>
    /// <param name="AAccessors">Further indices in <c>ARoot.Accessors</c> that may have become
    /// unused.</param>
    /// <param name="AWarnings">Receives a line for each step skipped; may be nil.</param>
    /// <returns>The number of meshes, skins, materials, textures, images and samplers
    /// deleted.</returns>
    /// <remarks>Works down from the objects given: meshes no node uses, skins no node uses, and
    /// materials no primitive uses are deleted; then the textures only the deleted materials
    /// used, the images and samplers only those textures used, and the accessors, bufferViews
    /// and buffer bytes only all of these used (see <see cref="DeleteUnusedData"/>). Every
    /// reference to the objects that follow is renumbered, texture references in material
    /// extensions and image references in texture extensions included. Objects the file never
    /// used are left alone, as only what the given objects lead to is considered. Materials are
    /// kept when the tree uses KHR_materials_variants, which refers to them from its own JSON; a
    /// warning says so.</remarks>
    class function DeleteUnusedObjects(ARoot: TglTF; const AMeshes, ASkins,
      AMaterials, AAccessors: TArray<Integer>; AWarnings: TStrings): Integer; static;

    //** @abstract(Calls a function for every texture reference in a material's JSON and
    //** replaces the index with what it returns.)
    //**
    //** A texture reference is an object with a numeric "index" under a name ending in
    //** "Texture", such as baseColorTexture, or clearcoatTexture inside an extension. The whole
    //** value is searched, so references in extensions are found too.
    //**
    //** @param(AValue A material, or part of one, as JSON; changed in place.)
    //**
    //** @param(AMap Returns the new texture index for an old one; returning the same index
    //** leaves it as it is.)
    /// <summary>Calls a function for every texture reference in a material's JSON and replaces
    /// the index with what it returns.</summary>
    /// <param name="AValue">A material, or part of one, as JSON; changed in place.</param>
    /// <param name="AMap">Returns the new texture index for an old one; returning the same
    /// index leaves it as it is.</param>
    /// <remarks>A texture reference is an object with a numeric "index" under a name ending in
    /// "Texture", such as baseColorTexture, or clearcoatTexture inside an extension. The whole
    /// value is searched, so references in extensions are found too.</remarks>
    class procedure RemapTextureRefs(AValue: TJSONValue; const AMap: TFunc<Integer, Integer>); static;

    //** @abstract(Tells which images the model needs: those a mesh shows.)
    //**
    //** An image is needed when a texture uses it that a material uses that a mesh primitive
    //** uses, texture references in material extensions and image references in texture
    //** extensions included. While KHR_materials_variants is used, every material counts as
    //** used, as that extension refers to materials from its own JSON.
    //**
    //** @param(ARoot The tree to check.)
    //**
    //** @returns(One flag per entry of @code(ARoot.Images), True for the images needed.)
    /// <summary>Tells which images the model needs: those a mesh shows.</summary>
    /// <param name="ARoot">The tree to check.</param>
    /// <returns>One flag per entry of <c>ARoot.Images</c>, True for the images
    /// needed.</returns>
    /// <remarks>An image is needed when a texture uses it that a material uses that a mesh
    /// primitive uses, texture references in material extensions and image references in
    /// texture extensions included. While KHR_materials_variants is used, every material
    /// counts as used, as that extension refers to materials from its own JSON.</remarks>
    class function ImagesInUse(ARoot: TglTF): TArray<Boolean>; static;

    //** @abstract(Deletes every material, texture, image and sampler the meshes do not lead to.)
    //**
    //** The images left are exactly those @link(ImagesInUse) reports as needed. Materials no
    //** primitive uses go first, then the textures no remaining material uses, then the images
    //** and samplers no remaining texture uses, and the bufferViews and buffer bytes only those
    //** images used. Every reference to the objects that follow is renumbered. Used on the
    //** copy made for a save, so that a saved file holds only the images it needs.
    //**
    //** @param(ARoot The tree to change.)
    //**
    //** @param(AWarnings Receives a line for each step skipped; may be nil.)
    //**
    //** @returns(The number of materials, textures, images and samplers deleted.)
    /// <summary>Deletes every material, texture, image and sampler the meshes do not lead
    /// to.</summary>
    /// <param name="ARoot">The tree to change.</param>
    /// <param name="AWarnings">Receives a line for each step skipped; may be nil.</param>
    /// <returns>The number of materials, textures, images and samplers deleted.</returns>
    /// <remarks>The images left are exactly those <see cref="ImagesInUse"/> reports as needed.
    /// Materials no primitive uses go first, then the textures no remaining material uses, then
    /// the images and samplers no remaining texture uses, and the bufferViews and buffer bytes
    /// only those images used. Every reference to the objects that follow is renumbered. Used on
    /// the copy made for a save, so that a saved file holds only the images it needs.</remarks>
    class function DeleteUnusedImages(ARoot: TglTF; AWarnings: TStrings): Integer; static;

    //** @abstract(Calls a function for every number under a given name in a JSON value and
    //** replaces it with what it returns.)
    //**
    //** Used for the "source" image references of textures, which texture extensions such as
    //** EXT_texture_webp repeat.
    //**
    //** @param(AValue The JSON to search, whole; changed in place.)
    //**
    //** @param(AName The property name, for example "source".)
    //**
    //** @param(AMap Returns the new value for an old one.)
    /// <summary>Calls a function for every number under a given name in a JSON value and
    /// replaces it with what it returns.</summary>
    /// <param name="AValue">The JSON to search, whole; changed in place.</param>
    /// <param name="AName">The property name, for example "source".</param>
    /// <param name="AMap">Returns the new value for an old one.</param>
    /// <remarks>Used for the "source" image references of textures, which texture extensions
    /// such as EXT_texture_webp repeat.</remarks>
    class procedure RemapNamedRefs(AValue: TJSONValue; const AName: string;
      const AMap: TFunc<Integer, Integer>); static;
  end;

implementation

const
  // Extensions known to refer to bufferViews or buffers from their own JSON
  BUFFERVIEW_EXTENSIONS: array[0..2] of string = (
    'KHR_draco_mesh_compression', 'EXT_meshopt_compression', 'KHR_meshopt_compression');

  // Extensions known to refer to accessors from their own JSON
  ACCESSOR_EXTENSIONS: array[0..0] of string = (
    'EXT_mesh_gpu_instancing');

// Sorts descending and removes repeats, so indices can be deleted in order
function DescendingUnique(const AValues: TArray<Integer>): TArray<Integer>;
var
  LList: TList<Integer>;
  LValue, I: Integer;
begin
  LList := TList<Integer>.Create;
  try
    for LValue in AValues do
      if not LList.Contains(LValue) then
        LList.Add(LValue);
    LList.Sort;
    SetLength(Result, LList.Count);
    for I := 0 to LList.Count - 1 do
      Result[I] := LList[LList.Count - 1 - I];
  finally
    LList.Free;
  end;
end;

// Removes up to 3 zero bytes at the end of a buffer that no bufferView
// uses: the padding added before data that has since been cut out
procedure TrimPadding(ARoot: TglTF; ABufferIndex: Integer);
var
  LBuffer: TglTFBuffer;
  LView: TglTFBufferView;
  LEnd, LLength: Int64;
  LData: TBytes;
begin
  LBuffer := ARoot.Buffers[ABufferIndex];
  LEnd := 0;
  for LView in ARoot.BufferViews do
    if (LView.Buffer = ABufferIndex) and (LView.ByteOffset + LView.ByteLength > LEnd) then
      LEnd := LView.ByteOffset + LView.ByteLength;

  LLength := Length(LBuffer.Data);
  while (LLength > LEnd) and (Length(LBuffer.Data) - LLength < 3) and
        (LBuffer.Data[LLength - 1] = 0) do
    Dec(LLength);
  if LLength < Length(LBuffer.Data) then
  begin
    LData := Copy(LBuffer.Data, 0, Integer(LLength));
    LBuffer.Data := LData;
    LBuffer.ByteLength := LLength;
  end;
end;


// Of the given bufferViews, deletes those nothing uses any more, then the
// padding left at the end of the buffers cut and the buffers left empty
procedure DeleteViewsIfUnused(ARoot: TglTF; const AViews: TArray<Integer>; AWarnings: TStrings);
var
  LUsed: TArray<Boolean>;
  LViews, LDelete, LBuffers: TArray<Integer>;
  LAccessor: TglTFAccessor;
  LImage: TglTFImage;
  LName: string;
  LIndex: Integer;

  procedure MarkUsed(AIndex: Integer);
  begin
    if (AIndex >= 0) and (AIndex < Length(LUsed)) then
      LUsed[AIndex] := True;
  end;

begin
  LViews := nil;
  for LIndex in AViews do
    if (LIndex >= 0) and (LIndex < ARoot.BufferViews.Count) then
      LViews := LViews + [LIndex];
  if LViews = nil then
    Exit;

  if TglTFEdit.UsesBufferViewExtension(ARoot, LName) then
  begin
    if Assigned(AWarnings) then
      AWarnings.Add(Format('The file uses %s, which refers to bufferViews in a way this program ' +
        'cannot renumber, so the bytes of data that is no longer used stay in the buffer', [LName]));
    Exit;
  end;

  // 1. Of those views, the ones nothing uses: one pass over the references
  SetLength(LUsed, ARoot.BufferViews.Count);
  for LAccessor in ARoot.Accessors do
  begin
    MarkUsed(LAccessor.BufferView);
    if Assigned(LAccessor.Sparse) then
    begin
      if Assigned(LAccessor.Sparse.Indices) then
        MarkUsed(LAccessor.Sparse.Indices.BufferView);
      if Assigned(LAccessor.Sparse.Values) then
        MarkUsed(LAccessor.Sparse.Values.BufferView);
    end;
  end;
  for LImage in ARoot.Images do
    MarkUsed(LImage.BufferView);
  LDelete := nil;
  LBuffers := nil;
  for LIndex in DescendingUnique(LViews) do
    if not LUsed[LIndex] then
    begin
      LDelete := LDelete + [LIndex];
      LBuffers := LBuffers + [ARoot.BufferViews[LIndex].Buffer];
    end;
  TglTFEdit.DeleteBufferViews(ARoot, LDelete);

  // 2. Padding left at the end of the buffers cut, and buffers that became
  //    empty: a buffer must have at least one byte (an emptied TBytes is
  //    nil, so ByteLength tells, not Data)
  for LIndex in DescendingUnique(LBuffers) do
    if (LIndex >= 0) and (LIndex < ARoot.Buffers.Count) then
    begin
      if ARoot.Buffers[LIndex].Data <> nil then
        TrimPadding(ARoot, LIndex);
      if (ARoot.Buffers[LIndex].ByteLength = 0) and not TglTFEdit.IsBufferUsed(ARoot, LIndex) then
        TglTFEdit.DeleteBuffer(ARoot, LIndex);
    end;
end;

{ TglTFEdit }

class function TglTFEdit.SameName(const A, B: string): Boolean;
begin
  // AnsiSameText compares with the platform's case rules, so not only A-Z
  Result := AnsiSameText(Trim(A), Trim(B));
end;

class function TglTFEdit.FindAnimation(ARoot: TglTF; const AName: string;
  AExcept: Integer): Integer;
var
  I: Integer;
begin
  if Trim(AName) <> '' then
    for I := 0 to ARoot.Animations.Count - 1 do
      if (I <> AExcept) and SameName(ARoot.Animations[I].Name, AName) then
        Exit(I);
  Result := -1;
end;

class function TglTFEdit.AnimationNameProblem(ARoot: TglTF; const AName: string;
  AExcept: Integer): string;
var
  LExisting: Integer;
begin
  if Trim(AName) = '' then
    Exit('The name is empty');
  LExisting := FindAnimation(ARoot, AName, AExcept);
  if LExisting >= 0 then
    Exit(Format('Animation %d is already called "%s"', [LExisting,
      ARoot.Animations[LExisting].Name]));
  Result := '';
end;

class function TglTFEdit.RenameAnimation(ARoot: TglTF; AIndex: Integer;
  const AName: string): string;
begin
  if (AIndex < 0) or (AIndex >= ARoot.Animations.Count) then
    Exit(Format('There is no animation %d', [AIndex]));
  Result := AnimationNameProblem(ARoot, AName, AIndex);
  if Result = '' then
    ARoot.Animations[AIndex].Name := Trim(AName);
end;

class function TglTFEdit.UsesBufferViewExtension(ARoot: TglTF; out AName: string): Boolean;
var
  LName: string;
begin
  for LName in BUFFERVIEW_EXTENSIONS do
    if ARoot.IsExtensionUsed(LName) then
    begin
      AName := LName;
      Exit(True);
    end;
  AName := '';
  Result := False;
end;

class function TglTFEdit.UsesAccessorExtension(ARoot: TglTF; out AName: string): Boolean;
var
  LName: string;
begin
  for LName in ACCESSOR_EXTENSIONS do
    if ARoot.IsExtensionUsed(LName) then
    begin
      AName := LName;
      Exit(True);
    end;
  AName := '';
  Result := False;
end;

class function TglTFEdit.IsAccessorUsed(ARoot: TglTF; AIndex: Integer): Boolean;
var
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LTarget: TglTFAttributeMap;
  LSkin: TglTFSkin;
  LAnimation: TglTFAnimation;
  LSampler: TglTFAnimationSampler;
begin
  Result := True;
  for LMesh in ARoot.Meshes do
    for LPrimitive in LMesh.Primitives do
    begin
      if (LPrimitive.Indices = AIndex) or LPrimitive.Attributes.ContainsValue(AIndex) then
        Exit;
      for LTarget in LPrimitive.Targets do
        if LTarget.ContainsValue(AIndex) then
          Exit;
    end;
  for LSkin in ARoot.Skins do
    if LSkin.InverseBindMatrices = AIndex then
      Exit;
  for LAnimation in ARoot.Animations do
    for LSampler in LAnimation.Samplers do
      if (LSampler.Input = AIndex) or (LSampler.Output = AIndex) then
        Exit;
  Result := False;
end;

class function TglTFEdit.IsBufferViewUsed(ARoot: TglTF; AIndex: Integer): Boolean;
var
  LAccessor: TglTFAccessor;
  LImage: TglTFImage;
begin
  Result := True;
  for LAccessor in ARoot.Accessors do
  begin
    if LAccessor.BufferView = AIndex then
      Exit;
    if Assigned(LAccessor.Sparse) then
    begin
      if Assigned(LAccessor.Sparse.Indices) and (LAccessor.Sparse.Indices.BufferView = AIndex) then
        Exit;
      if Assigned(LAccessor.Sparse.Values) and (LAccessor.Sparse.Values.BufferView = AIndex) then
        Exit;
    end;
  end;
  for LImage in ARoot.Images do
    if LImage.BufferView = AIndex then
      Exit;
  Result := False;
end;

class function TglTFEdit.IsBufferUsed(ARoot: TglTF; AIndex: Integer): Boolean;
var
  LView: TglTFBufferView;
begin
  for LView in ARoot.BufferViews do
    if LView.Buffer = AIndex then
      Exit(True);
  Result := False;
end;

class procedure TglTFEdit.DeleteAccessor(ARoot: TglTF; AIndex: Integer);
begin
  DeleteAccessors(ARoot, [AIndex]);
end;

class procedure TglTFEdit.DeleteAccessors(ARoot: TglTF; const AIndices: TArray<Integer>);
var
  LDelete: TArray<Boolean>;
  LMap: TArray<Integer>;
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LTarget: TglTFAttributeMap;
  LSkin: TglTFSkin;
  LAnimation: TglTFAnimation;
  LSampler: TglTFAnimationSampler;
  LIndex, LNew, I: Integer;

  function Mapped(AValue: Integer): Integer;
  begin
    if (AValue >= 0) and (AValue < Length(LMap)) then
      Result := LMap[AValue]
    else
      Result := AValue;
  end;

  procedure MapAttributes(AMap: TglTFAttributeMap);
  var
    LKey: string;
  begin
    // Keys first: a dictionary is not changed while it is enumerated
    for LKey in AMap.Keys.ToArray do
      AMap[LKey] := Mapped(AMap[LKey]);
  end;

begin
  // 1. Old index -> new index; deleted ones -> undefined
  SetLength(LDelete, ARoot.Accessors.Count);
  for LIndex in AIndices do
    if (LIndex >= 0) and (LIndex < Length(LDelete)) then
      LDelete[LIndex] := True;
  SetLength(LMap, Length(LDelete));
  LNew := 0;
  for I := 0 to High(LMap) do
    if LDelete[I] then
      LMap[I] := GLTF_UNDEFINED_INDEX
    else
    begin
      LMap[I] := LNew;
      Inc(LNew);
    end;
  if LNew = Length(LMap) then
    Exit; // nothing to delete

  // 2. The accessors themselves
  for I := High(LDelete) downto 0 do
    if LDelete[I] then
      ARoot.Accessors.Delete(I);

  // 3. Every reference, in one pass
  for LMesh in ARoot.Meshes do
    for LPrimitive in LMesh.Primitives do
    begin
      LPrimitive.Indices := Mapped(LPrimitive.Indices);
      MapAttributes(LPrimitive.Attributes);
      for LTarget in LPrimitive.Targets do
        MapAttributes(LTarget);
    end;
  for LSkin in ARoot.Skins do
    LSkin.InverseBindMatrices := Mapped(LSkin.InverseBindMatrices);
  for LAnimation in ARoot.Animations do
    for LSampler in LAnimation.Samplers do
    begin
      LSampler.Input := Mapped(LSampler.Input);
      LSampler.Output := Mapped(LSampler.Output);
    end;
end;

class procedure TglTFEdit.DeleteBufferView(ARoot: TglTF; AIndex: Integer);
begin
  DeleteBufferViews(ARoot, [AIndex]);
end;

class procedure TglTFEdit.DeleteBufferViews(ARoot: TglTF; const AIndices: TArray<Integer>);
type
  TCut = record
    Start, Stop: Int64; // bytes Start .. Stop - 1
  end;
var
  LDelete: TArray<Boolean>;
  LMap: TArray<Integer>;
  LCuts: TList<TCut>;
  LCut, LLast: TCut;
  LMerged: TArray<TCut>;
  LView: TglTFBufferView;
  LBuffer: TglTFBuffer;
  LData: TBytes;
  LAccessor: TglTFAccessor;
  LImage: TglTFImage;
  LBufferIndex, LIndex, LNew, I, J: Integer;
  LLength, LCount, LShift, LPos, LOut: Int64;

  // True when a view that stays in buffer LBufferIndex uses any of the
  // bytes AStart .. AStart + ACount - 1
  function OverlapsKept(AStart, ACount: Int64): Boolean;
  var
    K: Integer;
    LOther: TglTFBufferView;
  begin
    for K := 0 to ARoot.BufferViews.Count - 1 do
    begin
      LOther := ARoot.BufferViews[K];
      if not LDelete[K] and (LOther.Buffer = LBufferIndex) and
         (LOther.ByteOffset < AStart + ACount) and
         (LOther.ByteOffset + LOther.ByteLength > AStart) then
        Exit(True);
    end;
    Result := False;
  end;

  function Mapped(AValue: Integer): Integer;
  begin
    if (AValue >= 0) and (AValue < Length(LMap)) then
      Result := LMap[AValue]
    else
      Result := AValue;
  end;

begin
  SetLength(LDelete, ARoot.BufferViews.Count);
  for LIndex in AIndices do
    if (LIndex >= 0) and (LIndex < Length(LDelete)) then
      LDelete[LIndex] := True;

  LCuts := TList<TCut>.Create;
  try
    // 1. Each buffer that loses views is rebuilt once
    for LBufferIndex := 0 to ARoot.Buffers.Count - 1 do
    begin
      LBuffer := ARoot.Buffers[LBufferIndex];
      LLength := Length(LBuffer.Data);
      if LLength = 0 then
        Continue; // data not loaded: nothing to cut

      // The bytes of each view deleted: the view and its padding, or rounded
      // down to 4 when a remaining view uses the padding, or nothing when a
      // remaining view overlaps it. At the end of the buffer, whatever is left
      LCuts.Clear;
      for I := 0 to ARoot.BufferViews.Count - 1 do
      begin
        LView := ARoot.BufferViews[I];
        if not LDelete[I] or (LView.Buffer <> LBufferIndex) or (LView.ByteOffset < 0) or
           (LView.ByteOffset >= LLength) then
          Continue;
        LCount := (LView.ByteLength + 3) and not Int64(3);
        if LView.ByteOffset + LCount > LLength then
          LCount := LLength - LView.ByteOffset;
        if OverlapsKept(LView.ByteOffset, LCount) then
        begin
          LCount := LView.ByteLength - LView.ByteLength mod 4;
          if OverlapsKept(LView.ByteOffset, LCount) then
            LCount := 0;
        end;
        if LCount > 0 then
        begin
          LCut.Start := LView.ByteOffset;
          LCut.Stop := LView.ByteOffset + LCount;
          LCuts.Add(LCut);
        end;
      end;
      if LCuts.Count = 0 then
        Continue;

      // Merged in order; a merged cut keeps a length that is a multiple of
      // 4 unless it reaches the end, so the data after it keeps its alignment
      LCuts.Sort(TComparer<TCut>.Construct(
        function(const A, B: TCut): Integer
        begin
          if A.Start < B.Start then
            Result := -1
          else if A.Start > B.Start then
            Result := 1
          else
            Result := 0;
        end));
      LMerged := nil;
      for LCut in LCuts do
        if (Length(LMerged) > 0) and (LCut.Start <= LMerged[High(LMerged)].Stop) then
        begin
          if LCut.Stop > LMerged[High(LMerged)].Stop then
            LMerged[High(LMerged)].Stop := LCut.Stop;
        end
        else
          LMerged := LMerged + [LCut];
      for J := 0 to High(LMerged) do
        if LMerged[J].Stop < LLength then
          LMerged[J].Stop := LMerged[J].Start +
            ((LMerged[J].Stop - LMerged[J].Start) div 4) * 4;

      // The bytes that stay, in one new array (the old one may be shared
      // with another tree, so it is not changed)
      LCount := 0;
      for LLast in LMerged do
        Inc(LCount, LLast.Stop - LLast.Start);
      SetLength(LData, LLength - LCount);
      LPos := 0;
      LOut := 0;
      for LLast in LMerged do
      begin
        if LLast.Start > LPos then
        begin
          Move(LBuffer.Data[LPos], LData[LOut], LLast.Start - LPos);
          Inc(LOut, LLast.Start - LPos);
        end;
        LPos := LLast.Stop;
      end;
      if LPos < LLength then
        Move(LBuffer.Data[LPos], LData[LOut], LLength - LPos);
      LBuffer.Data := LData;
      LBuffer.ByteLength := Length(LData);

      // The remaining views move down by the bytes cut before them
      for I := 0 to ARoot.BufferViews.Count - 1 do
      begin
        LView := ARoot.BufferViews[I];
        if LDelete[I] or (LView.Buffer <> LBufferIndex) then
          Continue;
        LShift := 0;
        for LLast in LMerged do
          if LLast.Stop <= LView.ByteOffset then
            Inc(LShift, LLast.Stop - LLast.Start);
        LView.ByteOffset := LView.ByteOffset - LShift;
      end;
    end;
  finally
    LCuts.Free;
  end;

  // 2. The views themselves, and every reference renumbered in one pass
  SetLength(LMap, Length(LDelete));
  LNew := 0;
  for I := 0 to High(LMap) do
    if LDelete[I] then
      LMap[I] := GLTF_UNDEFINED_INDEX
    else
    begin
      LMap[I] := LNew;
      Inc(LNew);
    end;
  for I := High(LDelete) downto 0 do
    if LDelete[I] then
      ARoot.BufferViews.Delete(I);

  for LAccessor in ARoot.Accessors do
  begin
    LAccessor.BufferView := Mapped(LAccessor.BufferView);
    if Assigned(LAccessor.Sparse) then
    begin
      if Assigned(LAccessor.Sparse.Indices) then
        LAccessor.Sparse.Indices.BufferView := Mapped(LAccessor.Sparse.Indices.BufferView);
      if Assigned(LAccessor.Sparse.Values) then
        LAccessor.Sparse.Values.BufferView := Mapped(LAccessor.Sparse.Values.BufferView);
    end;
  end;
  for LImage in ARoot.Images do
    LImage.BufferView := Mapped(LImage.BufferView);
end;

class procedure TglTFEdit.DeleteBuffer(ARoot: TglTF; AIndex: Integer);
var
  LView: TglTFBufferView;
begin
  ARoot.Buffers.Delete(AIndex);
  for LView in ARoot.BufferViews do
    if LView.Buffer > AIndex then
      LView.Buffer := LView.Buffer - 1;
end;

class function TglTFEdit.DeleteUnusedData(ARoot: TglTF; const AAccessors: TArray<Integer>;
  AWarnings: TStrings): Integer;
var
  LUsed: TArray<Boolean>;
  LAccessors, LViews: TArray<Integer>;
  LAccessor: TglTFAccessor;
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LTarget: TglTFAttributeMap;
  LSkin: TglTFSkin;
  LAnimation: TglTFAnimation;
  LSampler: TglTFAnimationSampler;
  LName: string;
  LIndex, LValue: Integer;

  procedure Warn(const AText: string);
  begin
    if Assigned(AWarnings) then
      AWarnings.Add(AText);
  end;

  procedure MarkUsed(AIndex: Integer);
  begin
    if (AIndex >= 0) and (AIndex < Length(LUsed)) then
      LUsed[AIndex] := True;
  end;

  procedure AddView(AView: Integer);
  begin
    if (AView >= 0) and (AView < ARoot.BufferViews.Count) then
      LViews := LViews + [AView];
  end;

begin
  Result := 0;
  LAccessors := nil;
  LViews := nil;

  if UsesAccessorExtension(ARoot, LName) then
  begin
    Warn(Format('The file uses %s, which refers to accessors in a way this program cannot ' +
      'renumber, so data that is no longer used stays in the file', [LName]));
    Exit;
  end;

  // 1. Which accessors are still used: one pass over every reference
  SetLength(LUsed, ARoot.Accessors.Count);
  for LMesh in ARoot.Meshes do
    for LPrimitive in LMesh.Primitives do
    begin
      MarkUsed(LPrimitive.Indices);
      for LValue in LPrimitive.Attributes.Values do
        MarkUsed(LValue);
      for LTarget in LPrimitive.Targets do
        for LValue in LTarget.Values do
          MarkUsed(LValue);
    end;
  for LSkin in ARoot.Skins do
    MarkUsed(LSkin.InverseBindMatrices);
  for LAnimation in ARoot.Animations do
    for LSampler in LAnimation.Samplers do
    begin
      MarkUsed(LSampler.Input);
      MarkUsed(LSampler.Output);
    end;

  // 2. The given accessors nothing uses, and the views they lead to.
  //    Deleting accessors does not change bufferView indices
  for LIndex in DescendingUnique(AAccessors) do
    if (LIndex >= 0) and (LIndex < Length(LUsed)) and not LUsed[LIndex] then
    begin
      LAccessor := ARoot.Accessors[LIndex];
      AddView(LAccessor.BufferView);
      if Assigned(LAccessor.Sparse) then
      begin
        if Assigned(LAccessor.Sparse.Indices) then
          AddView(LAccessor.Sparse.Indices.BufferView);
        if Assigned(LAccessor.Sparse.Values) then
          AddView(LAccessor.Sparse.Values.BufferView);
      end;
      LAccessors := LAccessors + [LIndex];
    end;
  DeleteAccessors(ARoot, LAccessors);
  Result := Length(LAccessors);

  DeleteViewsIfUnused(ARoot, LViews, AWarnings);
end;

class function TglTFEdit.AnimationAccessors(AAnimation: TglTFAnimation): TArray<Integer>;
var
  LSampler: TglTFAnimationSampler;

  procedure Add(AValue: Integer);
  var
    LValue: Integer;
  begin
    for LValue in Result do
      if LValue = AValue then
        Exit;
    Result := Result + [AValue];
  end;

begin
  Result := nil;
  for LSampler in AAnimation.Samplers do
  begin
    Add(LSampler.Input);
    Add(LSampler.Output);
  end;
end;

class procedure TglTFEdit.DeleteAnimation(ARoot: TglTF; AIndex: Integer; AWarnings: TStrings);
var
  LAccessors: TArray<Integer>;
begin
  LAccessors := AnimationAccessors(ARoot.Animations[AIndex]);
  ARoot.Animations.Delete(AIndex);
  DeleteUnusedData(ARoot, LAccessors, AWarnings);
end;

class function TglTFEdit.ClearAnimations(ARoot: TglTF; AWarnings: TStrings): Integer;
var
  LAccessors: TArray<Integer>;
  LAnimation: TglTFAnimation;
begin
  LAccessors := nil;
  for LAnimation in ARoot.Animations do
    LAccessors := LAccessors + AnimationAccessors(LAnimation);
  Result := ARoot.Animations.Count;
  ARoot.Animations.Clear;
  DeleteUnusedData(ARoot, LAccessors, AWarnings);
end;

class function TglTFEdit.DataBuffer(ARoot: TglTF): Integer;
var
  LBuffer: TglTFBuffer;
begin
  if (ARoot.Buffers.Count > 0) and (ARoot.Buffers[0].Data <> nil) then
    Exit(0);
  LBuffer := TglTFBuffer.Create;
  LBuffer.ByteLength := 0;
  ARoot.Buffers.Add(LBuffer);
  Result := ARoot.Buffers.Count - 1;
end;

class function TglTFEdit.AppendBufferData(ARoot: TglTF; ABufferIndex: Integer;
  const AData: TBytes): Int64;
var
  LBuffer: TglTFBuffer;
  LData: TBytes;
  LPadding: Integer;
begin
  LBuffer := ARoot.Buffers[ABufferIndex];
  if (LBuffer.Data = nil) and (LBuffer.ByteLength > 0) then
    raise EglTFError.CreateFmt('Cannot add data to buffers[%d]: its data is not loaded',
      [ABufferIndex]);

  LData := Copy(LBuffer.Data);
  LPadding := (4 - Length(LData) mod 4) mod 4;
  Result := Length(LData) + LPadding;
  SetLength(LData, Result + Length(AData));
  if LPadding > 0 then
    FillChar(LData[Result - LPadding], LPadding, 0);
  if Length(AData) > 0 then
    Move(AData[0], LData[Result], Length(AData));
  LBuffer.Data := LData;
  LBuffer.ByteLength := Length(LData);
end;

class procedure TglTFEdit.AddExtensionUsed(ARoot: TglTF; const AName: string);
begin
  if not ARoot.IsExtensionUsed(AName) then
    ARoot.ExtensionsUsed := ARoot.ExtensionsUsed + [AName];
end;

// Old index -> new index when the given entries of a list of ACount objects
// are deleted; the deleted ones -> GLTF_UNDEFINED_INDEX
function DeletionMap(ACount: Integer; const AIndices: TArray<Integer>): TArray<Integer>;
var
  LDelete: TArray<Boolean>;
  LIndex, LNew, I: Integer;
begin
  SetLength(LDelete, ACount);
  for LIndex in AIndices do
    if (LIndex >= 0) and (LIndex < ACount) then
      LDelete[LIndex] := True;
  SetLength(Result, ACount);
  LNew := 0;
  for I := 0 to ACount - 1 do
    if LDelete[I] then
      Result[I] := GLTF_UNDEFINED_INDEX
    else
    begin
      Result[I] := LNew;
      Inc(LNew);
    end;
end;

// The new index of a reference; values outside the map (undefined or
// invalid) are left as they are
function MapIndex(const AMap: TArray<Integer>; AValue: Integer): Integer;
begin
  if (AValue >= 0) and (AValue < Length(AMap)) then
    Result := AMap[AValue]
  else
    Result := AValue;
end;

function DeletedCount(const AMap: TArray<Integer>): Integer;
var
  LValue: Integer;
begin
  Result := 0;
  for LValue in AMap do
    if LValue = GLTF_UNDEFINED_INDEX then
      Inc(Result);
end;

type
  // Deletes the entries a DeletionMap marks from any glTF object list
  TListDeleter = class
  public
    class procedure Apply<T: TglTFProperty, constructor>(AList: TglTFList<T>;
      const AMap: TArray<Integer>); static;
  end;

class procedure TListDeleter.Apply<T>(AList: TglTFList<T>; const AMap: TArray<Integer>);
var
  I: Integer;
begin
  for I := AList.Count - 1 downto 0 do
    if (I < Length(AMap)) and (AMap[I] = GLTF_UNDEFINED_INDEX) then
      AList.Delete(I);
end;

// The textures a material refers to, those in its extensions included
function MaterialTextures(AMaterial: TglTFMaterial): TArray<Integer>;
var
  LJSON: TJSONObject;
  LFound: TArray<Integer>;
begin
  LFound := nil;
  LJSON := AMaterial.SaveToJSON;
  try
    TglTFEdit.RemapTextureRefs(LJSON,
      function(AIndex: Integer): Integer
      begin
        LFound := LFound + [AIndex];
        Result := AIndex;
      end);
  finally
    LJSON.Free;
  end;
  Result := LFound;
end;

// The images a texture refers to: its source and those of its extensions,
// such as EXT_texture_webp
function TextureImages(ATexture: TglTFTexture): TArray<Integer>;
var
  LFound: TArray<Integer>;
begin
  LFound := nil;
  if ATexture.Source <> GLTF_UNDEFINED_INDEX then
    LFound := LFound + [ATexture.Source];
  if Assigned(ATexture.Extensions) then
    TglTFEdit.RemapNamedRefs(ATexture.Extensions, 'source',
      function(AIndex: Integer): Integer
      begin
        LFound := LFound + [AIndex];
        Result := AIndex;
      end);
  Result := LFound;
end;

procedure RenumberMaterialTextures(AMaterial: TglTFMaterial; const AMap: TArray<Integer>);
var
  LMap: TArray<Integer>;

  procedure Fix(AInfo: TglTFTextureInfo);
  begin
    if Assigned(AInfo) then
      AInfo.Index := MapIndex(LMap, AInfo.Index);
  end;

begin
  LMap := AMap;
  if Assigned(AMaterial.PbrMetallicRoughness) then
  begin
    Fix(AMaterial.PbrMetallicRoughness.BaseColorTexture);
    Fix(AMaterial.PbrMetallicRoughness.MetallicRoughnessTexture);
  end;
  Fix(AMaterial.NormalTexture);
  Fix(AMaterial.OcclusionTexture);
  Fix(AMaterial.EmissiveTexture);
  if Assigned(AMaterial.Extensions) then
    TglTFEdit.RemapTextureRefs(AMaterial.Extensions,
      function(AIndex: Integer): Integer
      begin
        Result := MapIndex(LMap, AIndex);
      end);
end;

procedure RenumberTextureImages(ATexture: TglTFTexture; const AMap: TArray<Integer>);
var
  LMap: TArray<Integer>;
begin
  LMap := AMap;
  ATexture.Source := MapIndex(LMap, ATexture.Source);
  if Assigned(ATexture.Extensions) then
    TglTFEdit.RemapNamedRefs(ATexture.Extensions, 'source',
      function(AIndex: Integer): Integer
      begin
        Result := MapIndex(LMap, AIndex);
      end);
end;

// Adds the values not in the list yet
procedure AddUnique(var AList: TArray<Integer>; const AValues: TArray<Integer>);
var
  LValue, LOld: Integer;
  LFound: Boolean;
begin
  for LValue in AValues do
  begin
    LFound := False;
    for LOld in AList do
      if LOld = LValue then
      begin
        LFound := True;
        Break;
      end;
    if not LFound then
      AList := AList + [LValue];
  end;
end;

class function TglTFEdit.IsMeshUsed(ARoot: TglTF; AIndex: Integer): Boolean;
var
  LNode: TglTFNode;
begin
  for LNode in ARoot.Nodes do
    if LNode.Mesh = AIndex then
      Exit(True);
  Result := False;
end;

class function TglTFEdit.IsSkinUsed(ARoot: TglTF; AIndex: Integer): Boolean;
var
  LNode: TglTFNode;
begin
  for LNode in ARoot.Nodes do
    if LNode.Skin = AIndex then
      Exit(True);
  Result := False;
end;

class procedure TglTFEdit.RemapTextureRefs(AValue: TJSONValue; const AMap: TFunc<Integer, Integer>);
var
  LObject, LInfo: TJSONObject;
  LPair: TJSONPair;
  LIndex: TJSONValue;
  LOld, LNew, I: Integer;
begin
  if AValue is TJSONObject then
  begin
    LObject := TJSONObject(AValue);
    for I := 0 to LObject.Count - 1 do
    begin
      LPair := LObject.Pairs[I];
      if LPair.JsonString.Value.EndsWith('Texture') and (LPair.JsonValue is TJSONObject) then
      begin
        LInfo := TJSONObject(LPair.JsonValue);
        LIndex := LInfo.GetValue('index');
        if LIndex is TJSONNumber then
        begin
          LOld := TJSONNumber(LIndex).AsInt;
          LNew := AMap(LOld);
          if LNew <> LOld then
          begin
            // The pair is replaced; the parent's pairs are not touched
            LInfo.RemovePair('index').Free;
            LInfo.AddPair('index', TJSONNumber.Create(LNew));
          end;
        end;
      end;
      RemapTextureRefs(LPair.JsonValue, AMap);
    end;
  end
  else if AValue is TJSONArray then
    for I := 0 to TJSONArray(AValue).Count - 1 do
      RemapTextureRefs(TJSONArray(AValue).Items[I], AMap);
end;

class procedure TglTFEdit.RemapNamedRefs(AValue: TJSONValue; const AName: string;
  const AMap: TFunc<Integer, Integer>);
var
  LObject: TJSONObject;
  LPair: TJSONPair;
  LValue: TJSONValue;
  LOld, LNew, I: Integer;
begin
  if AValue is TJSONObject then
  begin
    LObject := TJSONObject(AValue);
    // The number under AName first: replacing it changes the pair order, so
    // the nested values are walked afterwards
    LValue := LObject.GetValue(AName);
    if LValue is TJSONNumber then
    begin
      LOld := TJSONNumber(LValue).AsInt;
      LNew := AMap(LOld);
      if LNew <> LOld then
      begin
        LObject.RemovePair(AName).Free;
        LObject.AddPair(AName, TJSONNumber.Create(LNew));
      end;
    end;
    for I := 0 to LObject.Count - 1 do
    begin
      LPair := LObject.Pairs[I];
      if not (LPair.JsonValue is TJSONNumber) then
        RemapNamedRefs(LPair.JsonValue, AName, AMap);
    end;
  end
  else if AValue is TJSONArray then
    for I := 0 to TJSONArray(AValue).Count - 1 do
      RemapNamedRefs(TJSONArray(AValue).Items[I], AName, AMap);
end;

class procedure TglTFEdit.DeleteNodes(ARoot: TglTF; const AIndices: TArray<Integer>;
  AWarnings: TStrings);
var
  LMap: TArray<Integer>;
  LNode: TglTFNode;
  LScene: TglTFScene;
  LSkin: TglTFSkin;
  LAnimation: TglTFAnimation;
  LJoint, I, J: Integer;
  LEmptied: TArray<Integer>;

  function Deleted(AIndex: Integer): Boolean;
  begin
    Result := (AIndex >= 0) and (AIndex < Length(LMap)) and (LMap[AIndex] = GLTF_UNDEFINED_INDEX);
  end;

  // A deleted node is replaced by its children that stay, and those of its
  // children deleted too, in turn
  procedure AddKept(AList: TList<Integer>; AIndex, ADepth: Integer);
  var
    LChild: Integer;
  begin
    if ADepth > ARoot.Nodes.Count then
      Exit; // a cycle: invalid glTF, nothing sensible to do
    if not Deleted(AIndex) then
    begin
      if not AList.Contains(AIndex) then
        AList.Add(AIndex);
      Exit;
    end;
    for LChild in ARoot.Nodes[AIndex].Children do
      AddKept(AList, LChild, ADepth + 1);
  end;

  // A list of node references, with the deleted ones replaced and renumbered
  function Rebuilt(const AList: TArray<Integer>): TArray<Integer>;
  var
    LOut: TList<Integer>;
    LValue, K: Integer;
  begin
    LOut := TList<Integer>.Create;
    try
      for LValue in AList do
        AddKept(LOut, LValue, 0);
      SetLength(Result, LOut.Count);
      for K := 0 to LOut.Count - 1 do
        Result[K] := MapIndex(LMap, LOut[K]);
    finally
      LOut.Free;
    end;
  end;

begin
  LMap := DeletionMap(ARoot.Nodes.Count, AIndices);
  if DeletedCount(LMap) = 0 then
    Exit;

  // 1. A joint cannot go: the vertices refer to it by its place in the skin
  for LSkin in ARoot.Skins do
    for LJoint in LSkin.Joints do
      if Deleted(LJoint) then
        raise EglTFError.CreateFmt('Node %d cannot be deleted: it is a joint of a skin', [LJoint]);

  // 2. Every list of node references, while the deleted nodes and their
  //    children are still there to be read. Only the nodes that stay are
  //    changed, so the children of deleted ones read later are the old ones
  for I := 0 to ARoot.Nodes.Count - 1 do
    if not Deleted(I) then
    begin
      LNode := ARoot.Nodes[I];
      if Length(LNode.Children) > 0 then
        LNode.Children := Rebuilt(LNode.Children);
    end;
  for LScene in ARoot.Scenes do
    LScene.Nodes := Rebuilt(LScene.Nodes);

  // 3. Skins and animations
  for LSkin in ARoot.Skins do
  begin
    if Deleted(LSkin.Skeleton) then
      LSkin.Skeleton := GLTF_UNDEFINED_INDEX
    else
      LSkin.Skeleton := MapIndex(LMap, LSkin.Skeleton);
    LSkin.Joints := Rebuilt(LSkin.Joints); // none deleted: renumbered only
  end;
  LEmptied := nil;
  for I := 0 to ARoot.Animations.Count - 1 do
  begin
    LAnimation := ARoot.Animations[I];
    for J := LAnimation.Channels.Count - 1 downto 0 do
      if Deleted(LAnimation.Channels[J].Target.Node) then
        LAnimation.Channels.Delete(J)
      else
        LAnimation.Channels[J].Target.Node := MapIndex(LMap, LAnimation.Channels[J].Target.Node);
    if LAnimation.Channels.Count = 0 then
      LEmptied := LEmptied + [I];
  end;

  // 4. The nodes themselves, then the animations left without channels
  TListDeleter.Apply<TglTFNode>(ARoot.Nodes, LMap);
  for I := High(LEmptied) downto 0 do
  begin
    if Assigned(AWarnings) then
      AWarnings.Add(Format('Animation %d "%s" only animated nodes that were deleted, so it was ' +
        'deleted too', [LEmptied[I], ARoot.Animations[LEmptied[I]].Name]));
    DeleteAnimation(ARoot, LEmptied[I], AWarnings);
  end;
end;

function AllIndices(ACount: Integer): TArray<Integer>;
var
  I: Integer;
begin
  SetLength(Result, ACount);
  for I := 0 to ACount - 1 do
    Result[I] := I;
end;

// Deletes the candidate materials no primitive uses, then of the candidate
// textures and those the deleted materials used, the ones no remaining
// material uses; likewise the images and samplers. Every reference is
// renumbered. AViews receives the bufferViews the deleted images were in,
// still to be deleted when nothing else uses them. Returns the number of
// objects deleted
function DeleteMaterialChain(ARoot: TglTF; const AMaterials, ATextures, AImages,
  ASamplers: TArray<Integer>; var AViews: TArray<Integer>; AWarnings: TStrings): Integer;
var
  LMap: TArray<Integer>;
  LGone, LMaterials, LTextures, LImages, LSamplers: TArray<Integer>;
  LUsed: TArray<Boolean>;
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LMaterial: TglTFMaterial;
  LTexture: TglTFTexture;
  LIndex, LValue: Integer;

  procedure MarkUsed(AIndex: Integer);
  begin
    if (AIndex >= 0) and (AIndex < Length(LUsed)) then
      LUsed[AIndex] := True;
  end;

  // Of the candidates, those valid and not marked used
  function Unused(const ACandidates: TArray<Integer>; ACount: Integer): TArray<Integer>;
  var
    LCandidate: Integer;
  begin
    Result := nil;
    for LCandidate in ACandidates do
      if (LCandidate >= 0) and (LCandidate < ACount) and not LUsed[LCandidate] then
        AddUnique(Result, [LCandidate]);
  end;

begin
  Result := 0;
  LMaterials := AMaterials;
  LTextures := ATextures;
  LImages := AImages;
  LSamplers := ASamplers;

  // 1. Materials no primitive uses, with the textures they lead to
  if (LMaterials <> nil) and ARoot.IsExtensionUsed('KHR_materials_variants') then
  begin
    if Assigned(AWarnings) then
      AWarnings.Add('The file uses KHR_materials_variants, which refers to materials in a way ' +
        'this program cannot renumber, so materials that are no longer used stay in the file');
    LMaterials := nil;
  end;
  SetLength(LUsed, 0);
  SetLength(LUsed, ARoot.Materials.Count);
  for LMesh in ARoot.Meshes do
    for LPrimitive in LMesh.Primitives do
      MarkUsed(LPrimitive.Material);
  LGone := Unused(LMaterials, ARoot.Materials.Count);
  for LIndex in LGone do
    AddUnique(LTextures, MaterialTextures(ARoot.Materials[LIndex]));
  if LGone <> nil then
  begin
    LMap := DeletionMap(ARoot.Materials.Count, LGone);
    TListDeleter.Apply<TglTFMaterial>(ARoot.Materials, LMap);
    for LMesh in ARoot.Meshes do
      for LPrimitive in LMesh.Primitives do
        LPrimitive.Material := MapIndex(LMap, LPrimitive.Material);
    Inc(Result, Length(LGone));
  end;

  // 2. Textures no remaining material uses, extensions included, with the
  //    images and samplers they lead to
  SetLength(LUsed, 0);
  SetLength(LUsed, ARoot.Textures.Count);
  for LMaterial in ARoot.Materials do
    for LValue in MaterialTextures(LMaterial) do
      MarkUsed(LValue);
  LGone := Unused(LTextures, ARoot.Textures.Count);
  for LIndex in LGone do
  begin
    AddUnique(LImages, TextureImages(ARoot.Textures[LIndex]));
    if ARoot.Textures[LIndex].Sampler <> GLTF_UNDEFINED_INDEX then
      AddUnique(LSamplers, [ARoot.Textures[LIndex].Sampler]);
  end;
  if LGone <> nil then
  begin
    LMap := DeletionMap(ARoot.Textures.Count, LGone);
    TListDeleter.Apply<TglTFTexture>(ARoot.Textures, LMap);
    for LMaterial in ARoot.Materials do
      RenumberMaterialTextures(LMaterial, LMap);
    Inc(Result, Length(LGone));
  end;

  // 3. Images no remaining texture uses, with the bufferViews they were in
  SetLength(LUsed, 0);
  SetLength(LUsed, ARoot.Images.Count);
  for LTexture in ARoot.Textures do
    for LValue in TextureImages(LTexture) do
      MarkUsed(LValue);
  LGone := Unused(LImages, ARoot.Images.Count);
  for LIndex in LGone do
    if ARoot.Images[LIndex].BufferView <> GLTF_UNDEFINED_INDEX then
      AddUnique(AViews, [ARoot.Images[LIndex].BufferView]);
  if LGone <> nil then
  begin
    LMap := DeletionMap(ARoot.Images.Count, LGone);
    TListDeleter.Apply<TglTFImage>(ARoot.Images, LMap);
    for LTexture in ARoot.Textures do
      RenumberTextureImages(LTexture, LMap);
    Inc(Result, Length(LGone));
  end;

  // 4. Samplers no remaining texture uses
  SetLength(LUsed, 0);
  SetLength(LUsed, ARoot.Samplers.Count);
  for LTexture in ARoot.Textures do
    MarkUsed(LTexture.Sampler);
  LGone := Unused(LSamplers, ARoot.Samplers.Count);
  if LGone <> nil then
  begin
    LMap := DeletionMap(ARoot.Samplers.Count, LGone);
    TListDeleter.Apply<TglTFSampler>(ARoot.Samplers, LMap);
    for LTexture in ARoot.Textures do
      LTexture.Sampler := MapIndex(LMap, LTexture.Sampler);
    Inc(Result, Length(LGone));
  end;
end;

class function TglTFEdit.ImagesInUse(ARoot: TglTF): TArray<Boolean>;
var
  LMaterials, LTextures: TArray<Boolean>;
  LMesh: TglTFMesh;
  LPrimitive: TglTFMeshPrimitive;
  LValue, I: Integer;
begin
  // Materials a primitive uses (all of them while KHR_materials_variants,
  // which refers to materials from its own JSON, is used), the textures
  // those use, the images those use
  SetLength(LMaterials, ARoot.Materials.Count);
  if ARoot.IsExtensionUsed('KHR_materials_variants') then
    for I := 0 to High(LMaterials) do
      LMaterials[I] := True
  else
    for LMesh in ARoot.Meshes do
      for LPrimitive in LMesh.Primitives do
        if (LPrimitive.Material >= 0) and (LPrimitive.Material < Length(LMaterials)) then
          LMaterials[LPrimitive.Material] := True;

  SetLength(LTextures, ARoot.Textures.Count);
  for I := 0 to High(LMaterials) do
    if LMaterials[I] then
      for LValue in MaterialTextures(ARoot.Materials[I]) do
        if (LValue >= 0) and (LValue < Length(LTextures)) then
          LTextures[LValue] := True;

  SetLength(Result, ARoot.Images.Count);
  for I := 0 to High(LTextures) do
    if LTextures[I] then
      for LValue in TextureImages(ARoot.Textures[I]) do
        if (LValue >= 0) and (LValue < Length(Result)) then
          Result[LValue] := True;
end;

class function TglTFEdit.DeleteUnusedImages(ARoot: TglTF; AWarnings: TStrings): Integer;
var
  LViews: TArray<Integer>;
begin
  // Every material, texture, image and sampler is a candidate: those the
  // meshes do not lead to go
  LViews := nil;
  Result := DeleteMaterialChain(ARoot, AllIndices(ARoot.Materials.Count),
    AllIndices(ARoot.Textures.Count), AllIndices(ARoot.Images.Count),
    AllIndices(ARoot.Samplers.Count), LViews, AWarnings);
  if LViews <> nil then
    DeleteViewsIfUnused(ARoot, LViews, AWarnings);
end;

class function TglTFEdit.DeleteUnusedObjects(ARoot: TglTF; const AMeshes, ASkins,
  AMaterials, AAccessors: TArray<Integer>; AWarnings: TStrings): Integer;
var
  LMap: TArray<Integer>;
  LGone, LMaterials, LAccessors, LViews: TArray<Integer>;
  LUsed: TArray<Boolean>;
  LPrimitive: TglTFMeshPrimitive;
  LTarget: TglTFAttributeMap;
  LNode: TglTFNode;
  LIndex: Integer;

  procedure MarkUsed(AIndex: Integer);
  begin
    if (AIndex >= 0) and (AIndex < Length(LUsed)) then
      LUsed[AIndex] := True;
  end;

  // Of the candidates, those valid and not marked used
  function Unused(const ACandidates: TArray<Integer>; ACount: Integer): TArray<Integer>;
  var
    LCandidate: Integer;
  begin
    Result := nil;
    for LCandidate in ACandidates do
      if (LCandidate >= 0) and (LCandidate < ACount) and not LUsed[LCandidate] then
        AddUnique(Result, [LCandidate]);
  end;

begin
  Result := 0;
  LMaterials := AMaterials;
  LAccessors := AAccessors;
  LViews := nil;

  // 1. Meshes no node uses, with the accessors and materials they lead to
  SetLength(LUsed, 0);
  SetLength(LUsed, ARoot.Meshes.Count);
  for LNode in ARoot.Nodes do
    MarkUsed(LNode.Mesh);
  LGone := Unused(AMeshes, ARoot.Meshes.Count);
  for LIndex in LGone do
    for LPrimitive in ARoot.Meshes[LIndex].Primitives do
    begin
      LAccessors := LAccessors + [LPrimitive.Indices] + LPrimitive.Attributes.Values.ToArray;
      for LTarget in LPrimitive.Targets do
        LAccessors := LAccessors + LTarget.Values.ToArray;
      if LPrimitive.Material <> GLTF_UNDEFINED_INDEX then
        AddUnique(LMaterials, [LPrimitive.Material]);
    end;
  if LGone <> nil then
  begin
    LMap := DeletionMap(ARoot.Meshes.Count, LGone);
    TListDeleter.Apply<TglTFMesh>(ARoot.Meshes, LMap);
    for LNode in ARoot.Nodes do
      LNode.Mesh := MapIndex(LMap, LNode.Mesh);
    Inc(Result, Length(LGone));
  end;

  // 2. Skins no node uses, with their inverse bind matrices
  SetLength(LUsed, 0);
  SetLength(LUsed, ARoot.Skins.Count);
  for LNode in ARoot.Nodes do
    MarkUsed(LNode.Skin);
  LGone := Unused(ASkins, ARoot.Skins.Count);
  for LIndex in LGone do
    LAccessors := LAccessors + [ARoot.Skins[LIndex].InverseBindMatrices];
  if LGone <> nil then
  begin
    LMap := DeletionMap(ARoot.Skins.Count, LGone);
    TListDeleter.Apply<TglTFSkin>(ARoot.Skins, LMap);
    for LNode in ARoot.Nodes do
      LNode.Skin := MapIndex(LMap, LNode.Skin);
    Inc(Result, Length(LGone));
  end;

  // 3.-6. Materials no primitive uses, then the textures, images and
  //       samplers only those used
  Inc(Result, DeleteMaterialChain(ARoot, LMaterials, nil, nil, nil, LViews, AWarnings));

  // 7. The data: the views of the images first, as their indices were
  //    taken before anything else was deleted (deleting views renumbers
  //    the accessors' references, which DeleteUnusedData reads afterwards),
  //    then the accessors and the views only they used
  if LViews <> nil then
    DeleteViewsIfUnused(ARoot, LViews, AWarnings);
  DeleteUnusedData(ARoot, LAccessors, AWarnings);
end;

end.
