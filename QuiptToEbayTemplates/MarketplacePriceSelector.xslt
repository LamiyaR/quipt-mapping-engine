<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
    xmlns:q="http://schemas.quipt.com/api"
    exclude-result-prefixes="msxsl q">
  <xsl:import href="inventory.shared.xslt" />
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="q:InventoryVirtualResult" mode="pricing">
        <xsl:apply-templates select="." mode="CurrentPricing-SRP"/>
    </xsl:template>

    <xsl:template match="InventoryVirtualResult" mode="quantity">
      <xsl:variable name="calcQty">
        <xsl:apply-templates select="." mode="qty"/>
      </xsl:variable>
      <xsl:value-of select="$calcQty"/>
    </xsl:template>

    <xsl:template match="InventoryVirtualResult" mode="pricing">
        <xsl:apply-templates select="." mode="CurrentPricing-SRP"/>
    </xsl:template>
</xsl:stylesheet>
