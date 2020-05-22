## Wrapper class for creating structures and internal tables
Этот класс упрощает динамическое создание внутренних таблиц и структур со сложной структурой
Вместе с создаваемой таблицей заполняет field catalog для ALV 

Для установки этого на SAP сервер используйте [abapGit](https://docs.abapgit.org/)

Класс YDK_CL_CREATE_DATA:
```ABAP
CLASS ydk_cl_create_data DEFINITION.
  PUBLIC SECTION.
    DATA fc         TYPE        lvc_t_fcat.         " ALV field catalog, заполняется по мере добавления полей
    DATA fct        TYPE        abap_component_tab. " Таблица с описанием  структуры создаваемой таблицы
    DATA struct_ref TYPE REF TO data.               " Ссылка на созданную структуру
    DATA tab_ref    TYPE REF TO data.               " Ссылка на созданную таблицу

    " Добавление поля
    METHODS add_field
      IMPORTING
        !fname     TYPE clike          " Имя поля
        !ftype     TYPE clike OPTIONAL " Тип поля
        !flength   TYPE i     OPTIONAL " Размер (длина) поля
        !fdecimals TYPE i     OPTIONAL " Количество десятичных знаков
        !fdesc     TYPE clike OPTIONAL " Описание поля
        !like_data TYPE data  OPTIONAL." Такое же как переданное поле
	
    " Добавление структуры	
    METHODS add_structure
      IMPORTING
        !struct TYPE any.
	
    " Удаление поля	
    METHODS del_field
      IMPORTING
        !fieldname TYPE clike.
		
	" Создание структуры	
    METHODS create_structure
      RETURNING
        VALUE(struct_ref) TYPE REF TO data.
		
	" Создание таблицы
    METHODS create_tab
      EXPORTING
        !ret_struct_ref TYPE REF TO data
        !ret_tab_ref    TYPE REF TO data.
		
	" Отчистака данных объекта, подготовка к повторной работе
    METHODS clear.
ENDCLASS.
```

пример использования (это просто первый попавшийся кусок моего кода, добавлен без всякой правки)
```ABAP
* создадим таблицу для вывода данных
    DATA: crdt TYPE REF TO ydk_cl_create_data.
    CREATE OBJECT crdt.

    DATA: ls_out TYPE ty_out.

    crdt->add_structure( ls_out ).

    LOOP AT it_map ASSIGNING FIELD-SYMBOL(<map>).
        crdt->add_field( EXPORTING
          fname = |{ <map>-fname }_M|
          ftype = 'MSEG-MENGE'
          fdesc = |{ <map>-fdesc } Кол-во|
        ).
        crdt->add_field( EXPORTING
          fname = |{ <map>-fname }_P|
          ftype = 'MSEG-DMBTR'
          fdesc = |{ <map>-fdesc } Цена|
        ).
        crdt->add_field( EXPORTING
          fname = |{ <map>-fname }_S|
          ftype = 'MSEG-DMBTR'
          fdesc = |{ <map>-fdesc } Сумма|
        ).
    ENDLOOP.

    crdt->create_tab( ).
    out_tab = crdt->tab_ref.
    out_wa  = crdt->struct_ref.
    alv_fc = crdt->fc.

    FIELD-SYMBOLS <out_tab> TYPE STANDARD TABLE.
    ASSIGN out_tab->* TO <out_tab>.
```