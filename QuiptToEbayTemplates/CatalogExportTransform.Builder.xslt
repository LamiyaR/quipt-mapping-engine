<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:q="http://schemas.quipt.com/api"
    xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias"
    exclude-result-prefixes="axsl">

	<!--
  The purpose of this file is to take the serialized CatalogTemplateRequest.BuilderDetails, created with the help of the UITemplate,
  and build the CatalogExportTransform.<categoryId>.<index>.xslt file that will be used to create the catalog file for the specific category.
  -->

	<xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>

	<xsl:output method="xml" indent="yes"/>

	<xsl:param name="Type">XML</xsl:param>

	<!-- Current template contains only category-specific code that should be injected to the category-specific result template.
  Static part, that should be copied to all transforms extracted to the separate master template file and may be updated/debugged separately.
  All master template content (excluding xsl:stylesheet element declaration) will be copied to the output xslt. -->
	<xsl:variable name="MasterTemplateFile">CatalogExportTransform.Builder.MasterTemplate.xslt</xsl:variable>

	<!--
Expected builder details:
    - CategoryId: text.
    - Filter: xslt or text. If Filter field is empty, all items will be exported. If some xslt present, but xslt execution result is empty, item will be skipped, otherwise exported.
    - Attributes: Name, Value - xslt that produces pipe separated Value1|Value2 (if no pipe, only one Value is expected). 
  -->

	<!-- Build category-specific xslt using builder details -->
	<xsl:template match="/q:CatalogTemplateRequest.BuilderDetails">

		<!-- Create xsl:stylesheet element for the output file. It should be the same as in the the master template file. -->
		<axsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
					xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
					xmlns:xsd="http://www.w3.org/2001/XMLSchema"
					xmlns:q="http://schemas.quipt.com/api"
					xmlns:str="http://exslt.org/strings"
					xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
					xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
					xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl xsi xsd str q i">

			<!-- Copy xslt from the master template file -->
			<xsl:apply-templates select="document($MasterTemplateFile)" mode="copy-master-template"/>

			<!-- Render additional category-specific templates using data from CatalogTemplateRequest.Builder -->
			<axsl:template match="q:InventoryVirtualResult" mode="CategoryId">
				<axsl:text>
					<xsl:value-of select="normalize-space(q:Global/q:CatalogTemplateRequest.Property[q:Key='CategoryId']/q:Value)"/>
				</axsl:text>
			</axsl:template>
			<xsl:text>&#x0d;&#x0a;</xsl:text>

			<axsl:template match="q:InventoryVirtualResult" mode="Condition">
				<axsl:variable name="certRfb">
					<axsl:apply-templates select="." mode="certRfb"/>
				</axsl:variable>
				<axsl:variable name="sellerRfb">
					<axsl:apply-templates select="." mode="sellerRfb"/>
				</axsl:variable>
				<xsl:value-of disable-output-escaping="yes" select="q:Global/q:CatalogTemplateRequest.Property[q:Key='Condition']/q:Value"/>
			</axsl:template>
			<xsl:text>&#x0d;&#x0a;</xsl:text>

			<axsl:template match="q:InventoryVirtualResult" mode="Filter">
				<xsl:apply-templates select="q:Global/q:CatalogTemplateRequest.Property[q:Key='Filter']"/>
			</axsl:template>
			<xsl:text>&#x0d;&#x0a;</xsl:text>

			<axsl:template match="q:InventoryVirtualResult" mode="render-attributes">
				<xsl:apply-templates select="q:Attributes"/>
			</axsl:template>
			<xsl:text>&#x0d;&#x0a;</xsl:text>
			<axsl:template match="q:InventoryVirtualResult" mode="VariantAttributeMapping">
				<xsl:value-of disable-output-escaping="yes" select="normalize-space(q:Variants/q:CatalogTemplateRequest.Attribute/q:Properties/q:CatalogTemplateRequest.Property[q:Key='AttributeCodeMappings']/q:Value)"/>
			</axsl:template>

		</axsl:stylesheet>
	</xsl:template>

	<!-- Template to insert xslt that generates attributes -->
	<xsl:template match="q:Attributes">
		<xsl:for-each select="q:CatalogTemplateRequest.Attribute">
			<!-- render-attribute implementation moved to Builder.MasterTemplate -->
			<axsl:call-template name="render-attribute">
				<axsl:with-param name="name">
					<xsl:value-of select="normalize-space(q:Properties/q:CatalogTemplateRequest.Property[q:Key='Name']/q:Value)"/>
				</axsl:with-param>
				<axsl:with-param name="value">
					<xsl:value-of disable-output-escaping="yes" select="q:Properties/q:CatalogTemplateRequest.Property[q:Key='Value']/q:Value"/>
				</axsl:with-param>
			</axsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="q:Global/q:CatalogTemplateRequest.Property[q:Key='Filter']">
		<xsl:choose>
			<xsl:when test="normalize-space(q:Value)!=''">
				<axsl:variable name="includeItem">
					<xsl:value-of disable-output-escaping="yes" select="q:Value"/>
				</axsl:variable>
				<axsl:value-of select="normalize-space($includeItem)"/>
			</xsl:when>
			<xsl:otherwise>
				<axsl:text>No filter specified (export all)</axsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--Templates to copy xsl from master template to output excluding its xsl:stylesheet element-->
	<xsl:template match="/*" mode="copy-master-template">
		<xsl:apply-templates select="node()" mode="copy-master-template"/>
	</xsl:template>
	<xsl:template match="node() | @*" mode="copy-master-template">
		<xsl:copy>
			<xsl:apply-templates select="node() | @*" mode="copy-master-template"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>
