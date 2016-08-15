DECLARE
   --
   v_path      all_directories.directory_name%TYPE := 'UTL_PATH';
   v_file      utl_file.file_type;
   v_file_name VARCHAR2(100);
   v_count     NUMBER;
   --
   v_excel_header CLOB := '<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook
   xmlns="urn:schemas-microsoft-com:office:spreadsheet"
   xmlns:o="urn:schemas-microsoft-com:office:office"
   xmlns:x="urn:schemas-microsoft-com:office:excel"
   xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
   xmlns:html="http://www.w3.org/TR/REC-html40">
  <Styles>
    <Style ss:ID="Default" ss:Name="Normal">
      <Alignment ss:Vertical="Bottom" />
      <Borders />
      <Font />
      <Interior />
      <NumberFormat />
      <Protection />
    </Style>
    <Style ss:ID="bold">
      <Font ss:Bold="1" />
    </Style>
  </Styles>
  <Worksheet ss:Name="Sheet1">
    <Table>';
    --
    v_excel_footer CLOB := '</Table>
  </Worksheet>
</Workbook>';
--
BEGIN
   --
   -- Set up output file
   v_file_name := 'test.xls';
   v_file      := utl_file.fopen(v_path, v_file_name, 'w');
   --
   utl_file.put_line(v_file, v_excel_header);
   utl_file.put_line(v_file, '<Row>
        <Cell ss:MergeAcross="2">
          <Data ss:Type="String">Text in cell A1</Data>
        </ss:Cell>
      </Row>
      <Row>
        <Cell ss:StyleID="bold">
          <Data ss:Type="String">Bold text in A2</Data>
        </Cell>
      </Row>
      <Row ss:Index="4">
        <Cell ss:Index="2">
          <Data ss:Type="Number">43</Data>
        </Cell>
      </Row>');
   utl_file.put_line(v_file, v_excel_footer);
   --
   utl_file.fclose(v_file);
--
END;
/