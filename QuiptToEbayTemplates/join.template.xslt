<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                 xmlns:str="http://exslt.org/strings"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl str"
>
    <xsl:output method="xml" indent="yes"/>
  <!-- Template to join elements with separator '|'. Limits on each element max length (each element will be truncated) and on entire string length are applied.-->
  <!-- Count elements to join will be selected to fit the specified $maxLength. If $maxLength is omitted, all elements will be joined.-->
  <!--Example:Result of ("AAAA", "B", "CCC" ) with itemLength=3 and  entireLength=7 will be ("AAA","B")-->
  <xsl:template name="join">
    <xsl:param name="list" />
    <xsl:param name="prefix" />
    <xsl:param name="maxItemLength">5000</xsl:param>
    <xsl:param name="maxLength" />
    <xsl:param name="separator">|</xsl:param>

    <xsl:variable name="result">
      <xsl:call-template name="joinItems">
        <xsl:with-param name="maxItemLength" select="$maxItemLength"/>
        <xsl:with-param name="list" select="$list"/>
      <xsl:with-param name="prefix" select="$prefix"/>
        <xsl:with-param name="separator" select="$separator"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$maxLength != '' and string-length($result) &gt; $maxLength">
        <xsl:choose>
          <xsl:when test="contains($result, $separator)">
            <xsl:call-template name="substring-before-last">
              <xsl:with-param name="list" select="substring($result,1,$maxLength)"/>
              <xsl:with-param name="delimiter" select="$separator"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="substring($result,1,$maxLength)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$result"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Template to join elements with separator and element max length limit.-->
  <xsl:template name="joinItems">
    <xsl:param name="list" />
    <xsl:param name="prefix" />
    <xsl:param name="maxItemLength">5000</xsl:param>
    <xsl:param name="separator" />
    <xsl:for-each select="$list">
        <xsl:value-of select="substring(concat($prefix,normalize-space(.)),1,$maxItemLength)"/>
      <xsl:if test="position() != last()">
        <xsl:value-of select="$separator"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Template to determine Substring before last occurence of a specific delemiter-->
  <xsl:template name="substring-before-last">
    <!--passed template parameter -->
    <xsl:param name="list"/>
    <xsl:param name="delimiter"/>
    <xsl:choose>
      <xsl:when test="contains($list, $delimiter)">
        <!-- get everything in front of the first delimiter -->
        <xsl:value-of select="substring-before($list,$delimiter)"/>
        <xsl:choose>
          <xsl:when test="contains(substring-after($list,$delimiter),$delimiter)">
            <xsl:value-of select="$delimiter"/>
          </xsl:when>
        </xsl:choose>
        <xsl:call-template name="substring-before-last">
          <!-- store anything left in another variable -->
          <xsl:with-param name="list" select="substring-after($list,$delimiter)"/>
          <xsl:with-param name="delimiter" select="$delimiter"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
