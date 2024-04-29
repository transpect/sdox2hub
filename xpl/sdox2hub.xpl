<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step 
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:c="http://www.w3.org/ns/xproc-step" version="1.0"
  name="sdox2hub"
  type="tr:sdox2hub">
  
  <p:option name="input">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Input may be a URI or an OS path that represents a SDOX-file</p>
    </p:documentation>
  </p:option>  
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  <p:option name="debug" required="false" select="'yes'"/>
  <p:option name="zip-dir" required="false" select="''"/>
  
  <p:input port="sdox2hub-xsl">
    <p:document href="http://this.transpect.io/sdox2hub/xsl/sdox2hub.xsl"/>
  </p:input>
  
  <p:output port="result" primary="true">
    <p:pipe port="result" step="sd2hub"/>
  </p:output>
  
  <p:import href="http://transpect.io/calabash-extensions/unzip-extension/unzip-declaration.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <tr:file-uri name="file-uri">
    <p:with-option name="filename" select="$input"/>
  </tr:file-uri>
  
  <tr:unzip name="unzip">
    <p:with-option name="zip" select="/c:result/@local-href"/>
    <p:with-option name="dest-dir" select="concat(($zip-dir[not(.='')],string-join(tokenize(/c:result/@local-href,'/')[position () lt last()],'/'))[1],'/',replace(/c:result/@lastpath,'\.sdox$','.tmp'))"/>
  </tr:unzip>
  
  <p:load name="load-sd">
    <p:with-option name="href" select="concat(/c:files/@xml:base,'sd.xml')"/>
  </p:load>
  
  <p:xslt initial-mode="sdox2hub" name="sd2hub">
    <p:input port="stylesheet">
      <p:pipe port="sdox2hub-xsl" step="sdox2hub"/>
    </p:input>
    <p:input port="source">
      <p:pipe port="result" step="load-sd"/>
    </p:input>
    <p:with-param name="oi-file" select="concat(concat(($zip-dir[not(.='')],string-join(tokenize(/c:result/@local-href,'/')[position () lt last()],'/'))[1],'/',replace(/c:result/@lastpath,'\.sdox$','.tmp')),'/organization_information.xml')">
      <p:pipe port="result" step="file-uri"/>
    </p:with-param>
  </p:xslt>
  
</p:declare-step>