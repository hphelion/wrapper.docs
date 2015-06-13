<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:local="urn:functions:local"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  exclude-result-prefixes="xs xd local m"
  version="2.0">
  <!-- Transform unnamespaced HTML docs into namespaced XHTML docs are required by the epub spec. 
  
       Also cleans up anything generated by the base Toolkit HTML transforms that is not allowed
       in ePub XHTML.
      -->
  
  <xsl:template match="html | HTML" mode="html2xhtml" priority="10">
    <xsl:param name="topicref" as="element()?" tunnel="yes"/>
    <xsl:variable name="lang" select="if ($topicref) then root($topicref)/*/@xml:lang else ''"/>
    <html>
    <xsl:choose>
      <xsl:when test="$lang != ''">
        <xsl:attribute name="xml:lang" select="$lang"/>
      </xsl:when>
      <xsl:otherwise/><!-- No lang attribute -->
    </xsl:choose>
      <xsl:apply-templates mode="#current"/>
    </html>
  </xsl:template>
  
  <xsl:template mode="html2xhtml" match="img[not(@alt)]">
    <xsl:element name="{name(.)}">
      <xsl:attribute name="alt" select="@src"/>
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template mode="html2xhtml" match="math | m:math" xmlns="http://www.w3.org/1998/Math/MathML">
    <xsl:element name="{name(.)}">
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <!-- <a> elements used for IDs are not used in XHTML -->
  <xsl:template match="a[@name and not(@href)]" priority="10" mode="html2xhtml"/>
  
  <xsl:template match="a/@name" mode="html2xhtml" priority="10">
    <xsl:attribute name="id" select="string(.)"/>
  </xsl:template>
  
  <xsl:template match="a[@href]" priority="20" mode="html2xhtml">
    <xsl:variable name="newHref" select="@href" as="xs:string"/>
    <a>
      <xsl:attribute name="href" select="$newHref"/>
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </a>
  </xsl:template>
  
  <xsl:template match="blockquote" priority="20" mode="html2xhtml">
    <blockquote>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*|text()" 
        group-adjacent="local:getBlockOrInlineGroupingKey(.)">
        <xsl:choose>
          <xsl:when test="current-grouping-key() = 'inline'">
            <xsl:if test="normalize-space(.) != '' and normalize-space(.) != ' '">
              <p><xsl:apply-templates select="current-group()" mode="#current"/></p>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>        
      </xsl:for-each-group>
    </blockquote>
  </xsl:template>  
  
  <xsl:template mode="html2xhtml" match="*">
    <xsl:element name="{name(.)}">
      <xsl:apply-templates select="@*,node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="u" priority="10" mode="html2xhtml">
    <!-- DITA <u> (underline element) -->
    <span class="underline" style="text-decoration: underline"><xsl:apply-templates mode="#current"/></span>
  </xsl:template>
  
  <xsl:template match="span/p" priority="10" mode="html2xhtml">
    <!-- Paragraphs not allowed within span -->
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="p/div" priority="10" mode="html2xhtml">
    <span>
      <xsl:apply-templates select="@*,node()" mode="#current"
      /></span>
  </xsl:template>
  
  <xsl:template  mode="html2xhtml" match="img/@width | img/@height" priority="100">
    <!--  Suppress for now because of issue with ImgUtils not working and generating
          bad values for height and width. -->
    <xsl:variable name="length" as="xs:string" select="."/>
    <xsl:choose>
      <xsl:when test="starts-with($length, '-')">
        <xsl:message> + [WARN] Value "<xsl:sequence select="$length"/>" for <xsl:sequence select="name(..)"/>/@<xsl:sequence select="name(.)"/> is negative. This reflects a bug in the Open Toolkit.</xsl:message>
        <xsl:message> + [WARN]   Suppressing attribute in HTML output.</xsl:message>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="effectiveLength" as="xs:string"
          select="if (matches($length, '[0-9]+'))
          then concat($length, 'px')
          else $length
          "
        />
        <xsl:attribute name="{name(.)}" select="$effectiveLength"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template  mode="html2xhtml" match="video/@width" priority="20">
    <xsl:copy/>  
  </xsl:template>
  
  <xsl:template  mode="html2xhtml" match="script/@type" priority="30">
  	<xsl:copy/>
  </xsl:template>
  
  <xsl:template  mode="html2xhtml" match="
    @lang |
    @target |
    @compact |
    @width |
    @type |
    @xxx
    " priority="10"/>
  
  <xsl:template mode="html2xhtml" match="@*|text()|processing-instruction()|comment()">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:function name="local:isBlock" as="xs:boolean">
    <xsl:param name="context" as="node()"/>
    <xsl:variable name="result" as="xs:boolean"
      select="
      $context/self::address or
      $context/self::blockquote or
      $context/self::del or
      $context/self::div or
      $context/self::dl or
      $context/self::fieldset or
      $context/self::form or
      $context/self::h1 or
      $context/self::hr or
      $context/self::ins or
      $context/self::noscript or
      $context/self::ol or
      $context/self::p or
      $context/self::pre or
      $context/self::script or
      $context/self::table or
      $context/self::ul
      "
    />
    <xsl:sequence select="$result"/>    
  </xsl:function>
    
  <xsl:function name="local:getBlockOrInlineGroupingKey" as="xs:string">
    <xsl:param name="context" as="node()"/>
    <xsl:choose>
      <xsl:when 
        test="local:isBlock($context)">
        <xsl:sequence select="'block'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="'inline'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>
