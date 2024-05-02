<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:dbk="http://docbook.org/ns/docbook"
  xmlns:tr="http://transpect.io"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:sd="https://smashdocs.net/sd"
  xmlns="http://docbook.org/ns/docbook"
  version="2.0" 
  exclude-result-prefixes = "xs fn tr">
  
  <xsl:param name="hub-version" select="'1.2'" as="xs:string"/>
  <xsl:param name="oi-file" select="string-join((tokenize(base-uri(),'[\\/]')[position() lt last()],'organization_information.xml'),'/')"/>
  <xsl:param name="portrait-table-width" select="17.1"/>
  <xsl:param name="landscape-table-width" select="25"/>
  
  <xsl:variable name="oi-file-content" select="if (doc-available($oi-file)) then document($oi-file) else ()"/>
  <xsl:variable name="lang" select="tokenize(//meta/language/@value,'_')[1]"/>
  
  <!--  catch-all -->
  <xsl:template match="node() | @*" mode="#all" priority="-5">
    <xsl:copy xmlns="https://smashdocs.net/sd">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="smashdoc" mode="sdox2hub">
    <hub>
      <xsl:apply-templates select="meta" mode="#current"/>
      <info>
        <css:rules>
          <xsl:apply-templates select="$oi-file-content//style" mode="#current"/>
        </css:rules>  
      </info>
      <xsl:apply-templates select="node() except meta" mode="#current"/>
    </hub>
  </xsl:template>
  
  <xsl:template match="style" mode="sdox2hub">
    <xsl:variable name="layout-type" select="replace(parent::*/name(),'Styles$','')"/>
    <css:rule>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="layout-type" select="('para'[$layout-type='paragraph'],$layout-type)[1]"/>
      <xsl:if test="$oi-file-content//numbering/numberedStyles//numberingItem[@src=current()/@name]">
        <xsl:attribute name="css:list-style-type" select="$oi-file-content//numbering/numberedStyles//numberingItem[@src=current()/@name]/numeratedListFormat"/>
        <xsl:attribute name="numbering-level" select="count($oi-file-content//numbering/numberedStyles//level[numberingItem[@src=current()/@name]]/preceding-sibling::level)+1"/>
        <xsl:attribute name="numbering-multilevel-type" select="('single'[count($oi-file-content//numbering/numberedStyles/group[descendant::numberingItem[@src=current()/@name]]/level)=1],'multi')[1]"/>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </css:rule>
  </xsl:template>
  
  <xsl:template match="textCss" mode="sdox2hub">
    <xsl:for-each select="tokenize(.,'\s*;\s*')">
      <xsl:choose>
        <xsl:when test="tokenize(.,'\s*:\s*')[1]=('border-top','border-right','border-bottom','border-left')">
          <xsl:variable name="name" select="tokenize(.,'\s*:\s*')[1]"/>
          <xsl:for-each select="tokenize(tokenize(.,'\s*:\s*')[2],' ')">
            <xsl:variable name="context" select="."/>
            <xsl:attribute name="css:{$name}-{('color'[matches($context,'^#')],'width'[matches($context,'^[0-9\.]+(pt|mm|cm|px|em|ex|%)$')],'style')[1]}" select="."/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="css:{tokenize(.,'\s*:\s*')[1]}" select="tokenize(.,'\s*:\s*')[2]"/>    
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="@name" mode="sdox2hub">
    <xsl:next-match/>
    <xsl:attribute name="native-name" select="."/>
  </xsl:template>
  
  <xsl:template match="directory" mode="sdox2hub">
    <div role="hub:toc">
      <xsl:apply-templates select="preceding-sibling::*[1][self::pagebreak] | @*, node()" mode="#current">
        <xsl:with-param name="display" select="true()"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>
  
  <xsl:template match="paragraph" mode="sdox2hub">
    <para>
      <xsl:apply-templates select="preceding-sibling::*[1][self::pagebreak] | @*" mode="#current">
        <xsl:with-param name="display" select="true()"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="$oi-file-content//bulletItem[@src=current()/@stylename]/bulletListFormat" mode="#current"/>
      <xsl:apply-templates select="latest/node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="bulletListFormat" mode="sdox2hub">
    <phrase role="hub:identifier">
      <xsl:apply-templates mode="#current"/>
    </phrase>
    <tab role="docx2hub:generated"/>
  </xsl:template>
  
  <xsl:template match="image" mode="sdox2hub">
    <figure>
      <xsl:apply-templates select="@* except (@numbering-value) | preceding-sibling::*[1][self::pagebreak]" mode="#current">
        <xsl:with-param name="display" select="true()"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="latest/caption, latest/source" mode="#current"/>
      <xsl:if test="latest/node()[not(self::caption or self::source)]">
        <caption>
          <xsl:apply-templates select="latest/node()[not(self::caption or self::source)]" mode="#current"/>
        </caption>
      </xsl:if>
    </figure>
  </xsl:template>
  
  <xsl:template match="image[latest/caption[not(node())]]" mode="sdox2hub">
    <informalfigure>
      <xsl:apply-templates select="@* except (@numbering-value) | preceding-sibling::*[1][self::pagebreak]" mode="#current">
        <xsl:with-param name="display" select="true()"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="latest/source" mode="#current"/>
      <xsl:if test="latest/node()[not(self::caption or self::source)]">
        <caption>
          <xsl:apply-templates select="latest/node()[not(self::caption or self::source)]" mode="#current"/>
        </caption>
      </xsl:if>
    </informalfigure>
  </xsl:template>
  
  <xsl:template match="table" mode="sdox2hub">
    <table>
      <xsl:apply-templates select="@* except (@numbering-value) | preceding-sibling::*[1][self::pagebreak]" mode="#current">
        <xsl:with-param name="display" select="true()"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="latest/caption" mode="#current"/>
      <xsl:if test="latest/node()[not(self::caption or self::tr or self::column_width)]">
        <textobject>
          <xsl:apply-templates select="latest/node()[not(self::caption or self::tr or self::column_width)]" mode="#current"/>
        </textobject>
      </xsl:if>
      <tgroup cols="{count(latest/column_width/item)}">
        <xsl:apply-templates select="latest/column_width" mode="#current"/>
        <xsl:for-each-group select="latest/tr" group-adjacent="child::*[1]/name()">
          <xsl:element name="t{('head'[current-grouping-key()='th'],'body')[1]}">
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:element>
        </xsl:for-each-group>
      </tgroup>
    </table>
  </xsl:template>

  <xsl:template match="column_width/item" mode="sdox2hub">
    <colspec colnum="{count(preceding-sibling::item)+1}" colname="col{count(preceding-sibling::item)+1}" colwidth="{text()}"/>
  </xsl:template>

  <xsl:template match="tr" mode="sdox2hub">
    <row>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </row>
  </xsl:template>
  
  <xsl:template match="td | th" mode="sdox2hub">
    <entry>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-adjacent="name()">
        <xsl:choose>
          <xsl:when test="current-grouping-key()='ul-li'">
            <itemizedlist>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </itemizedlist>
          </xsl:when>
          <xsl:when test="current-grouping-key()='ol-li'">
            <orderedlist>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </orderedlist>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </entry>
  </xsl:template>
  
  <xsl:template match="ol-li | ul-li" mode="sdox2hub">
    <listitem>
      <xsl:apply-templates select="@*" mode="#current"/>
      <para>
        <xsl:apply-templates mode="#current"/>  
      </para>
    </listitem>
  </xsl:template>
  
  <xsl:template match="formula" mode="sdox2hub">
    <para role="Formula">
      <xsl:apply-templates select="@* except (@numbering-value) | preceding-sibling::*[1][self::pagebreak]" mode="#current">
        <xsl:with-param name="display" select="true()"/>
      </xsl:apply-templates>
      <xsl:apply-templates select="latest/node()[not(self::caption)], @numbering-value" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="latest/*:math" mode="sdox2hub">
    <equation>
      <xsl:apply-templates select="parent::latest/caption[child::node()]" mode="#current"/>
      <xsl:next-match/>
    </equation>
  </xsl:template>
  
  <xsl:template match="latest/caption | caption[node()]" mode="sdox2hub">
    <title>
      <xsl:apply-templates select="parent::latest/parent::*/@numbering-value" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </title>
  </xsl:template>
  
  <xsl:template match="source" mode="sdox2hub">
    <mediaobject>
      <imageobject>
        <imagedata>
          <xsl:attribute name="fileref" select="text()"/>
        </imagedata>
      </imageobject>
    </mediaobject>
  </xsl:template>
  
  <xsl:template match="inline-image" mode="sdox2hub">
    <inlinemediaobject>
      <imageobject>
        <imagedata>
          <xsl:attribute name="fileref" select="@src"/>
        </imagedata>
      </imageobject>
    </inlinemediaobject>
  </xsl:template>
  
  <xsl:template match="latest | redline | column_width | ins | insacc | indexes | bibliographies | meta" mode="sdox2hub">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="history | 
                       tex | 
                       comments | 
                       h | 
                       caption[not(child::node())] | 
                       del | 
                       delacc | 
                       section-tags | 
                       attached-sections | 
                       division-separators |
                       title |
                       filename |
                       subtitle |
                       description |
                       footer |
                       creator |
                       creator_id |
                       created_date |
                       supplemental |
                       tags |
                       word-export-presets |
                       grid-indentation-enabled |
                       grid |
                       sectionTypes | 
                       contentInSecondLine |
                       extraHangingIndentation |
                       extraHangingIndentationAtGrid |
                       showInToc |
                       tocIndentation |
                       tocLevel |
                       translatedName" mode="sdox2hub" priority="-1"/>
  
  <xsl:template match="language" mode="sdox2hub">
    <xsl:attribute name="xml:lang" select="tokenize(@value,'_')[1]"/>
  </xsl:template>
  
  <xsl:template match="p" mode="sdox2hub">
    <para>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </para>
  </xsl:template>
  
  <xsl:template match="footnote" mode="sdox2hub">
    <footnote>
      <xsl:apply-templates select="@* | node() | //attached-sections//*[@id=current()/@href]" mode="#current"/>
    </footnote>
  </xsl:template>
  
  <xsl:template match="inline-formula" mode="sdox2hub">
    <inlineequation>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </inlineequation>
  </xsl:template>
  
  <xsl:template match="a" mode="sdox2hub">
    <link xlink:href="{replace(@href,'^#','')}">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </link>
  </xsl:template>
  
  <xsl:template match="xref" mode="sdox2hub">
    <link linkend="{concat('_',replace(@href,'^#',''))}">
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </link>
  </xsl:template>
  
  <xsl:template match="sup" mode="sdox2hub">
    <superscript>
      <xsl:apply-templates mode="#current"/>
    </superscript>
  </xsl:template>
  
  <xsl:template match="sub" mode="sdox2hub">
    <subscript>
      <xsl:apply-templates mode="#current"/>
    </subscript>
  </xsl:template>
  
  <xsl:template match="i" mode="sdox2hub">
    <phrase css:font-style="italic">
      <xsl:apply-templates mode="#current"/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="b" mode="sdox2hub">
    <phrase css:font-weight="bold">
      <xsl:apply-templates mode="#current"/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="u" mode="sdox2hub">
    <phrase css:text-decoration-line="underline">
      <xsl:apply-templates mode="#current"/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="s" mode="sdox2hub">
    <phrase css:text-decoration-line="line-through">
      <xsl:apply-templates mode="#current"/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="sd-sc" mode="sdox2hub">
    <phrase css:font-variant="small-caps">
      <xsl:apply-templates mode="#current"/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="kbd" mode="sdox2hub">
    <phrase css:font-family="Courier New">
      <xsl:apply-templates mode="#current"/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="inline" mode="sdox2hub">
    <phrase>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="br" mode="sdox2hub">
    <xsl:element name="{name()}"/>
  </xsl:template>
  
  <xsl:template match="index" mode="sdox2hub">
    <xsl:variable name="primary-target-index" select="//indexes//index-code[@id=current()/@data-id]" as="element(index-code)"/>
    <indexterm>
      <primary>
        <xsl:value-of select="$primary-target-index/@title"/>
      </primary>
      <xsl:if test="$primary-target-index/@target-reference-id or $primary-target-index/index-code">
        <xsl:variable name="secondary-target-index" select="//indexes//index-code[@id=$primary-target-index/@target-reference-id] | $primary-target-index/index-code" as="element(index-code)*"/>
        <secondary>
          <xsl:value-of select="$secondary-target-index"/>
        </secondary>
        <xsl:if test="$secondary-target-index/@target-reference-id or $secondary-target-index/index-code">
          <xsl:variable name="tertiary-target-index" select="//indexes//index-code[@id=$secondary-target-index/@target-reference-id] | $secondary-target-index/index-code" as="element(index-code)*"/>
          <tertiary>
            <xsl:value-of select="$tertiary-target-index"/>
          </tertiary>
        </xsl:if>
      </xsl:if>
    </indexterm>
  </xsl:template>
  
  <xsl:template match="paragraph/latest/p" mode="sdox2hub">
    <xsl:apply-templates select="@* | node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="document | ordered-sections | numberingCss" mode="sdox2hub">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="pagebreak" mode="sdox2hub">
    <xsl:param name="display" select="false()"/>
    <xsl:if test="$display">
      <xsl:attribute name="css:page-break-before" select="'always'"/>  
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@stylename | @type" mode="sdox2hub">
    <xsl:attribute name="role" select="."/>
  </xsl:template>
  
  <xsl:template match="@style" mode="sdox2hub">
    <xsl:for-each select="tokenize(.,'\s*;\s*')">
      <xsl:attribute name="css:{tokenize(.,'\s*:\s*')[1]}" select="tokenize(.,'\s*:\s*')[2]"/>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="@indent" mode="sdox2hub">
    <xsl:if test="not(.='0')">
      <xsl:attribute name="css:margin-left" select="concat(//meta/grid/item[position() = current()+1],'cm')"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@alignment" mode="sdox2hub">
    <xsl:attribute name="css:text-align" select="."/>
  </xsl:template>
  
  <xsl:template match="ordered-sections//@id" mode="sdox2hub">
    <xsl:if test="some $href in //@href satisfies xs:string($href)=(xs:string(.), concat('#',xs:string(.)))">
      <xsl:attribute name="xml:id" select="concat('_',.)"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@archived | 
                       @supplemental | 
                       @external_id | 
                       @fromGraphic | 
                       @caption |
                       @width | 
                       @level | 
                       @is-first-in-current-level |
                       @tex |
                       @data-caption |
                       @data-tex |
                       @table-name |
                       @table-type |
                       @row-id |
                       @cell-type |
                       @ins |
                       @del |
                       @i_r |
                       @i_c |
                       @background-intensity |
                       @data-num-enabled |
                       @data-content-enabled |
                       @data-pagenumber-enabled |
                       @target-id | 
                       @restartNumbering |
                       @num-enabled |
                       @list-id |
                       @orientation_switch |
                       *[not(ancestor-or-self::ordered-sections)]/@id |
                       @href |
                       ul-li/@enumeration" mode="sdox2hub" priority="-1"/>
  
  <xsl:template match="@border-color | 
                       @min-height | 
                       @font-size | 
                       @text-align | 
                       @vertical-align | 
                       @background-color" mode="sdox2hub">
    <xsl:attribute name="css:{name()}" select="."/>
  </xsl:template>
  
  <xsl:template match="@border-top | @border-right | @border-bottom | @border-left" mode="sdox2hub">
    <xsl:variable name="name" select="local-name()"/>
    <xsl:for-each select="tokenize(.,' ')">
      <xsl:variable name="context" select="."/>
      <xsl:attribute name="css:{$name}-{('color'[matches($context,'^#')],'width'[matches($context,'^[0-9\.]+(pt|mm|cm|px|em|ex|%)$')],'style')[1]}" select="."/>
    </xsl:for-each>
  </xsl:template>
  
  <!--  TODO -->
  <xsl:template match="image/@orientation_switch | ol-li/@enumeration" mode="sdox2hub" priority="-.5">
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="image/@numbering-value" mode="sdox2hub">
    <phrase role="hub:caption-number">
      <xsl:value-of select="('Bild '[$lang='de'],'Figure ')[1]"/>
      <phrase role="hub:identifier">
        <xsl:value-of select="."/>
      </phrase>
    </phrase>
    <tab role="docx2hub:generated"/>
  </xsl:template>
  
  <xsl:template match="table/@numbering-value" mode="sdox2hub">
    <phrase role="hub:caption-number">
      <xsl:value-of select="('Tabelle '[$lang='de'],'Table ')[1]"/>
      <phrase role="hub:identifier">
        <xsl:value-of select="."/>
      </phrase>
    </phrase>
    <tab role="docx2hub:generated"/>
  </xsl:template>
  
  <xsl:template match="table/@orientation_switch" mode="sdox2hub">
    <xsl:attribute name="orient" select="substring(.,1,4)"/>
  </xsl:template>
  
  <xsl:template match="table/@width" mode="sdox2hub">
    <xsl:variable name="width" select="."/>
    <xsl:attribute name="css:{name()}" select="($width[not(matches($width,'%$'))],
                                                concat(($landscape-table-width * number(replace($width,'%$','')) div 100),'cm')[$width/parent::table/@orientation_switch='landscape'],
                                                concat(($portrait-table-width * number(replace($width,'%$','')) div 100),'cm'))[1]"/>
  </xsl:template>
  
  <xsl:template match="@rowspan" mode="sdox2hub">
    <xsl:attribute name="morerows" select="max((. - 1, 0))"/>
  </xsl:template>
  
  <xsl:template match="@colspan" mode="sdox2hub">
    <xsl:attribute name="namest" select="concat('col',parent::*/@i_c + 1)"/>
    <xsl:attribute name="nameend" select="concat('col',parent::*/@i_c + .)"/>
  </xsl:template>
  
  <xsl:template match="*[not(@colspan)]/@i_c" mode="sdox2hub">
    <xsl:attribute name="colname" select="concat('col',. + 1)"/>
  </xsl:template>
  
  <xsl:template match="@numbering-value" mode="sdox2hub">
    <phrase role="hub:identifier">
      <xsl:value-of select="."/>
    </phrase>
    <tab role="docx2hub:generated"/>
  </xsl:template>
  
  <xsl:template match="formula/@numbering-value" mode="sdox2hub">
    <tab role="docx2hub:generated"/>
    <phrase role="hub:identifier">
      <xsl:value-of select="."/>
    </phrase>
  </xsl:template>
  
  <xsl:template match="footnote/@numbering-value" mode="sdox2hub">
    <xsl:attribute name="label" select="."/>
  </xsl:template>
  
</xsl:stylesheet>
