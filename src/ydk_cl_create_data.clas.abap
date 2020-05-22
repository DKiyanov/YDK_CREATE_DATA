class YDK_CL_CREATE_DATA definition
  public
  final
  create public .

public section.

  data FC type LVC_T_FCAT .
  type-pools ABAP .
  data FCT type ABAP_COMPONENT_TAB .
  data STRUCT_REF type ref to DATA .
  data TAB_REF type ref to DATA .

  methods ADD_FIELD
    importing
      !FNAME type CLIKE
      !FTYPE type CLIKE optional
      !FLENGTH type I optional
      !FDECIMALS type I optional
      !FDESC type CLIKE optional
      !LIKE_DATA type DATA optional .
  methods ADD_STRUCTURE
    importing
      !STRUCT type ANY .
  methods DEL_FIELD
    importing
      !FIELDNAME type CLIKE .
  methods CREATE_STRUCTURE
    returning
      value(STRUCT_REF) type ref to DATA .
  methods CREATE_TAB
    exporting
      !RET_STRUCT_REF type ref to DATA
      !RET_TAB_REF type ref to DATA .
  methods CLEAR .
protected section.
private section.
ENDCLASS.



CLASS YDK_CL_CREATE_DATA IMPLEMENTATION.


  METHOD add_field.
    DATA: l TYPE i.
    DATA: xdd03l TYPE dd_x031l_table.
    DATA: elemdescr TYPE REF TO cl_abap_elemdescr.

    READ TABLE fct WITH KEY name = fname TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.

    FIELD-SYMBOLS <fc> LIKE LINE OF fc.
    FIELD-SYMBOLS <fct> LIKE LINE OF fct.

    APPEND INITIAL LINE TO fc ASSIGNING <fc>.
    APPEND INITIAL LINE TO fct ASSIGNING <fct>.

    <fct>-name = fname.
    TRANSLATE <fct>-name TO UPPER CASE.

    l = strlen( ftype ).

    IF l <= 1 AND like_data IS NOT SUPPLIED.
      CASE ftype.
        WHEN ' '. <fct>-type ?= cl_abap_elemdescr=>get_string( ).
        WHEN 'g'. <fct>-type ?= cl_abap_elemdescr=>get_string( ).
        WHEN 'I'. <fct>-type ?= cl_abap_elemdescr=>get_i( ).
        WHEN 'F'. <fct>-type ?= cl_abap_elemdescr=>get_f( ).
        WHEN 'D'. <fct>-type ?= cl_abap_elemdescr=>get_d( ).
        WHEN 'T'. <fct>-type ?= cl_abap_elemdescr=>get_t( ).
        WHEN 'C'. <fct>-type ?= cl_abap_elemdescr=>get_c( p_length = flength ).
        WHEN 'N'. <fct>-type ?= cl_abap_elemdescr=>get_n( p_length = flength ).
        WHEN 'X'. <fct>-type ?= cl_abap_elemdescr=>get_x( p_length = flength ).
        WHEN 'P'. <fct>-type ?= cl_abap_elemdescr=>get_p( p_length = flength p_decimals = fdecimals ).
      ENDCASE.
    ELSE.
      IF like_data IS SUPPLIED.
        <fct>-type ?= cl_abap_elemdescr=>describe_by_data( like_data ).
      ELSE.
        <fct>-type ?= cl_abap_elemdescr=>describe_by_name( ftype ).
      ENDIF.

      IF <fct>-type->kind = <fct>-type->kind_elem.
        CALL METHOD <fct>-type->get_ddic_object
          RECEIVING
            p_object     = xdd03l[]
          EXCEPTIONS
            not_found    = 1
            no_ddic_type = 2
            OTHERS       = 3.

        IF sy-subrc = 0.
          READ TABLE xdd03l ASSIGNING FIELD-SYMBOL(<xdd03l>) INDEX 1.
          IF <xdd03l>-rollname IS INITIAL.
            elemdescr ?= <fct>-type.
            <fc>-rollname = elemdescr->help_id.
          ELSE.
            <fc>-rollname = <xdd03l>-rollname.
          ENDIF.
          <fc>-convexit = <xdd03l>-convexit.
          <fc>-datatype = <xdd03l>-dtyp.
        ENDIF.
      ENDIF.
    ENDIF.

    <fc>-fieldname = fname.
    <fc>-tabname   = 1.
    <fc>-inttype   = <fct>-type->type_kind.
    <fc>-intlen    = <fct>-type->length.
    <fc>-decimals  = <fct>-type->decimals.
    <fc>-reptext   = fdesc.

    DATA: tabname   TYPE dd03t-tabname.
    DATA: fieldname TYPE dd03t-fieldname.
    DATA: ddtext    TYPE dd03t-ddtext.

    IF fdesc IS INITIAL AND ftype CA '-'.
      SPLIT ftype AT '-' INTO tabname fieldname.

      SELECT SINGLE ddtext INTO ddtext
        FROM dd03t
       WHERE tabname = tabname
         AND ddlanguage = sy-langu
         AND as4local = 'A'
         AND fieldname = fieldname.
      <fc>-reptext   = ddtext.
    ENDIF.

    <fc>-coltext   = <fc>-reptext.
    <fc>-tooltip   = <fc>-reptext.
    <fc>-scrtext_l = <fc>-reptext.
    <fc>-scrtext_s = <fc>-reptext.
    <fc>-scrtext_m = <fc>-reptext.
  ENDMETHOD.


  METHOD add_structure.
    DATA: typedescr   TYPE REF TO cl_abap_typedescr.
    DATA: structdescr TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS: <component> TYPE abap_compdescr.
    DATA: ftype TYPE c LENGTH 30.
    FIELD-SYMBOLS: <fld> TYPE any.
    FIELD-SYMBOLS: <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS: <struct> TYPE any.

    CALL METHOD cl_abap_datadescr=>describe_by_data
      EXPORTING
        p_data      = struct
      RECEIVING
        p_descr_ref = typedescr.

    IF typedescr->kind = typedescr->kind_table.
      DATA: tabdescr TYPE REF TO cl_abap_tabledescr.
      tabdescr ?= typedescr.
      typedescr = tabdescr->get_table_line_type( ).
      ASSIGN struct TO <tab>.
      IF <tab> IS INITIAL.
        DATA: row_ref TYPE REF TO data.
        CREATE DATA row_ref LIKE LINE OF <tab>.
        ASSIGN row_ref->* TO <struct>.
      ELSE.
        READ TABLE <tab> ASSIGNING <struct> INDEX 1.
      ENDIF.
    ELSE.
      ASSIGN struct TO <struct>.
    ENDIF.

    structdescr ?= typedescr.

    LOOP AT structdescr->components ASSIGNING <component>.
      CHECK <component>-name <> 'MANDT'.

      READ TABLE fct WITH KEY name = <component>-name TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.

      ASSIGN COMPONENT <component>-name OF STRUCTURE <struct> TO <fld>.

      add_field( fname = <component>-name like_data = <fld> ).
    ENDLOOP.
  ENDMETHOD.


  METHOD clear.
    CLEAR: fc, fct, struct_ref, tab_ref.
  ENDMETHOD.


  METHOD create_structure.
    DATA: struct_descr TYPE REF TO cl_abap_structdescr.

    struct_descr ?= cl_abap_structdescr=>create( fct ).
    CREATE DATA struct_ref TYPE HANDLE struct_descr.
  ENDMETHOD.


  METHOD create_tab.
    DATA: struct_descr TYPE REF TO cl_abap_structdescr.
    FIELD-SYMBOLS <struct> TYPE any.

    struct_descr ?= cl_abap_structdescr=>create( fct ).
    CREATE DATA struct_ref TYPE HANDLE struct_descr.

    ASSIGN struct_ref->* TO <struct>.
    CREATE DATA tab_ref LIKE TABLE OF <struct>.

    IF ret_struct_ref IS BOUND.
      ret_struct_ref = struct_ref.
    ENDIF.

    IF ret_tab_ref IS BOUND.
      ret_tab_ref = tab_ref.
    ENDIF.
  ENDMETHOD.


  METHOD del_field.
    DELETE fc  WHERE fieldname = fieldname.
    DELETE fct WHERE name = fieldname.
  ENDMETHOD.
ENDCLASS.
