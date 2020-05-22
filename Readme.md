## Wrapper class for creating structures and internal tables
This class makes it easy to dynamically create internal tables and structures with complex structure.
Together with the created table it fills the field catalog for ALV 

To install this on SAP server, use [abapGit](https://docs.abapgit.org/)

Class YDK_CL_CREATE_DATA:
```ABAP
CLASS ydk_cl_create_data DEFINITION.
  PUBLIC SECTION.
    DATA fc         TYPE        lvc_t_fcat.         " ALV field catalog, filled as you add fields
    DATA fct        TYPE        abap_component_tab. " The table with the description of the structure of the created table
    DATA struct_ref TYPE REF TO data.               " Reference to the created structure
    DATA tab_ref    TYPE REF TO data.               " Reference to the created table

    " Adding a field
    METHODS add_field
      IMPORTING
        !fname     TYPE clike          " Field name
        !ftype     TYPE clike OPTIONAL " Field type
        !flength   TYPE i     OPTIONAL " Size (length) of field
        !fdecimals TYPE i     OPTIONAL " Number of decimal places
        !fdesc     TYPE clike OPTIONAL " Field description
        !like_data TYPE data  OPTIONAL." Same as the passed field
	
    " Adding a structure	
    METHODS add_structure
      IMPORTING
        !struct TYPE any.
	
    " Delete field	
    METHODS del_field
      IMPORTING
        !fieldname TYPE clike.
		
	" Creation of structure	
    METHODS create_structure
      RETURNING
        VALUE(struct_ref) TYPE REF TO data.
		
	" Creation of table
    METHODS create_tab
      EXPORTING
        !ret_struct_ref TYPE REF TO data
        !ret_tab_ref    TYPE REF TO data.
		
	" Object data clearing, preparation for repeated work
    METHODS clear.
ENDCLASS.
```

usage example (this is just the first piece of my code that came across, added without any editing)
```ABAP
* create a table for data output
    DATA: crdt TYPE REF TO ydk_cl_create_data.
    CREATE OBJECT crdt.

    DATA: ls_out TYPE ty_out.

    crdt->add_structure( ls_out ).

    LOOP AT it_map ASSIGNING FIELD-SYMBOL(<map>).
		crdt->add_field( EXPORTING
		  fname = |{ <map>-fname }_M|
		  ftype = 'MSEG-MENGE'
		  fdesc = |{ <map>-fdesc } Quantity|
		).
		crdt->add_field( EXPORTING
		  fname = |{ <map>-fname }_P|
		  ftype = 'MSEG-DMBTR'
		  fdesc = |{ <map>-fdesc } Price|
		).
		crdt->add_field( EXPORTING
		  fname = |{ <map>-fname }_S|
		  ftype = 'MSEG-DMBTR'
		  fdesc = |{ <map>-fdesc } Amount|
		).
    ENDLOOP.

    crdt->create_tab( ).
    out_tab = crdt->tab_ref.
    out_wa  = crdt->struct_ref.
    alv_fc = crdt->fc.

    FIELD-SYMBOLS <out_tab> TYPE STANDARD TABLE.
    ASSIGN out_tab->* TO <out_tab>.
```