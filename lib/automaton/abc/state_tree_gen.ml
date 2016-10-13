module H = Ast_helper
module C = Abc_common

let (!!) s = s ^ "_"

module Arg : Generator.ARG with type result = Parsetree.structure_item =
struct
  type result = Parsetree.structure_item
  type middle = Parsetree.type_declaration

  let name = "State tree"

  let state_typ = [%type: StateI.t]

  let middle_of_record type_name fields =
    let fields =
      List.map
        (
          fun field ->
            H.Type.field
              (Location.mknoloc !!(field.Types.ld_id.Ident.name))
              state_typ
        )
        fields
    in
    H.Type.mk
      ~kind:(Parsetree.Ptype_record fields)
      (Location.mknoloc type_name)

  let middle_of_variant name constructors =
    let constructors =
      List.map
        (
          fun constructor ->
           H.Type.constructor
              ~args:(List.map (fun _ -> state_typ) constructor.Types.cd_args)
              (Location.mknoloc !!(constructor.Types.cd_id.Ident.name))
        )
        constructors
    in
    H.Type.mk
      ~kind:(Parsetree.Ptype_variant constructors)
      (Location.mknoloc name)

  let middle_of_abstract name =
    H.Type.mk
      ~manifest:state_typ
      (Location.mknoloc name)

  let middle_of_alias name _rec _env value =
    match value.Types.desc with
    | Types.Ttuple args ->
      H.Type.mk
        ~manifest:(H.Typ.tuple (List.map (fun _ -> state_typ) args))
        (Location.mknoloc name)
    | Types.Tconstr (constr_path, _::_, _) ->
      H.Type.mk
        ~manifest:(H.Typ.constr
                     (Location.mknoloc
                      @@ C.flatten
                      @@ C.longident_of_path constr_path)
                     [])
        (Location.mknoloc name)
    | _ ->
      middle_of_abstract name

  let result_of_middle typedefs =
    H.Str.type_
      (List.map
         (fun td -> {td with Parsetree.ptype_attributes = C.deriving })
         typedefs)
end

include Generator.Make (Arg)
