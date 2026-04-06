<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:q="http://schemas.quipt.com/api"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl q"
>
	<xsl:output method="xml" indent="yes"/>

	<!-- 
  Vendor services warehouse/channel code mapping
  
  If USEOVERRIDE='True' then use WAREMAP_ and CHANMAP_ keys for store and warehouse ids.
  If USEOVERRIDE missing or 'False' use current mappings.
  If USEOVERRIDE='True' and match not found, return empty value.
  
  Expected WAREMAP format (CHANMAP format is similar):
  
  <xsl:param name="WAREMAP">
  <array>
			<a key="WAREMAP_QuiptCode1" value="serviceCode1" />
			<a key="WAREMAP_QuiptCode1" value="serviceCode2" />
		</array>
 </xsl:param>
  -->
	<xsl:param name="USEOVERRIDE"/>
	<xsl:param name="WAREMAP"/>
	<xsl:param name="CHANMAP"/>

	<xsl:template match="q:Channel" mode="vserv-channel">
		<xsl:call-template name="vserv-channel">
			<xsl:with-param name="quiptCode" select="q:Code"/>
		</xsl:call-template>
	</xsl:template>
        <xsl:template match="q:Channel" mode="vserv-channel-by-relationshipid">
		<xsl:call-template name="vserv-channel">
			<xsl:with-param name="quiptCode" select="q:Code"/>
			<xsl:with-param name="quiptId" select="q:RelationshipId"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="q:Channel" mode="vserv-channel-by-id">
		<xsl:call-template name="vserv-channel">
			<xsl:with-param name="quiptCode" select="q:Code"/>
			<xsl:with-param name="quiptId" select="q:Id"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="Channel" mode="vserv-channel">
		<xsl:call-template name="vserv-channel">
			<xsl:with-param name="quiptCode" select="Code"/>
		</xsl:call-template>
	</xsl:template>
        <xsl:template match="Channel" mode="vserv-channel-by-relationshipid">
		<xsl:call-template name="vserv-channel">
			<xsl:with-param name="quiptCode" select="Code"/>
			<xsl:with-param name="quiptId" select="RelationshipId"/>
		</xsl:call-template>
        </xsl:template>
	<xsl:template match="Channel" mode="vserv-channel-by-id">
		<xsl:call-template name="vserv-channel">
			<xsl:with-param name="quiptCode" select="Code"/>
			<xsl:with-param name="quiptId" select="Id"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="q:Location" mode="vserv-warehouse">
		<xsl:call-template name="vserv-warehouse">
			<xsl:with-param name="quiptCode" select="q:Code"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="Location" mode="vserv-warehouse">
		<xsl:call-template name="vserv-warehouse">
			<xsl:with-param name="quiptCode" select="Code"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="q:Warehouse" mode="vserv-warehouse">
		<xsl:call-template name="vserv-warehouse">
			<xsl:with-param name="quiptCode" select="q:Code"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="Warehouse" mode="vserv-warehouse">
		<xsl:call-template name="vserv-warehouse">
			<xsl:with-param name="quiptCode" select="Code"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="q:ReturnTo" mode="vserv-warehouse">
		<xsl:call-template name="vserv-warehouse">
			<xsl:with-param name="quiptCode" select="q:Code"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="ReturnTo" mode="vserv-warehouse">
		<xsl:call-template name="vserv-warehouse">
			<xsl:with-param name="quiptCode" select="Code"/>
		</xsl:call-template>
	</xsl:template>
	<!-- get vendor service warehouse by Quipt warehouse code -->
	<xsl:template name="vserv-warehouse">
		<xsl:param name="quiptCode"/>
		<xsl:choose>
			<xsl:when test="translate($USEOVERRIDE,'true','TRUE')='TRUE'">
				<xsl:variable name="map" select="msxsl:node-set($WAREMAP)/array"/>
				<xsl:value-of select="string($map/a[@key=concat('WAREMAP_',$quiptCode)]/@value)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$quiptCode"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- get Quipt warehouse code by vendor service warehouse -->
	<xsl:template name="vserv-quiptwarehousecode">
		<xsl:param name="warehouse"/>
		<xsl:choose>
			<xsl:when test="translate($USEOVERRIDE,'true','TRUE')='TRUE'">
				<xsl:variable name="map" select="msxsl:node-set($WAREMAP)/array"/>
				<xsl:value-of select="substring-after($map/a[@value=normalize-space($warehouse)]/@key,'WAREMAP_')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$warehouse"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- get vendor service channel by Quipt channel code -->
	<xsl:template name="vserv-channel">
		<xsl:param name="quiptCode"/>
		<xsl:param name="quiptId"/>
		<xsl:choose>
			<xsl:when test="translate($USEOVERRIDE,'true','TRUE')='TRUE' and $quiptId != ''">
				<xsl:variable name="map" select="msxsl:node-set($CHANMAP)/array"/>
				<xsl:value-of select="string($map/a[@key=concat('CHANMAP_',$quiptId)]/@value)"/>
			</xsl:when>
			<xsl:when test="translate($USEOVERRIDE,'true','TRUE')='TRUE' and $quiptCode != ''">
				<xsl:variable name="map" select="msxsl:node-set($CHANMAP)/array"/>
				<xsl:value-of select="string($map/a[@key=concat('CHANMAP_',$quiptCode)]/@value)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$quiptCode"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>



	<!--Table for encoding/decoding special symbols from Encoding.xml-->
	<xsl:variable name="encoding-map">
		<SkuEncoding>
			<Symbol original="#" encoded="-23-"/>
			<Symbol original="+" encoded="-2B-"/>
			<Symbol original="_" encoded="-5F-"/>
			<Symbol original="*" encoded="-2A-"/>
		</SkuEncoding>
	</xsl:variable>

	<!--Template to encode sku-->
	<xsl:template name="encodeSku">
	  <xsl:param name="sku"/>
	  <xsl:choose>
		<xsl:when test="$sku = 'APP-EARPODS+ADP-BN'">APP-EARPODS+ADP-BN</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="encode-string">
				<xsl:with-param name="encodingTable" select="msxsl:node-set($encoding-map)/SkuEncoding"/>
				<xsl:with-param name="text" select="$sku"/>
				<xsl:with-param name="encodingElementIndex" select="1"/>
				<xsl:with-param name="encode" select="1"/>
			</xsl:call-template>
		</xsl:otherwise>
	  </xsl:choose>
	</xsl:template>

	<!--Template to decode encoded sku-->
	<xsl:template name="decodeSku">
	  <xsl:param name="sku"/>
	  <xsl:choose>
		<xsl:when test="$sku = 'APP-EARPODS+ADP-BN'">APP-EARPODS+ADP-BN</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="encode-string">
				<xsl:with-param name="encodingTable" select="msxsl:node-set($encoding-map)/SkuEncoding"/>
				<xsl:with-param name="text" select="$sku"/>
				<xsl:with-param name="encodingElementIndex" select="1"/>
				<xsl:with-param name="encode" select="0"/>
			</xsl:call-template>
		</xsl:otherwise>
	  </xsl:choose>
	</xsl:template>

	<!--Encodes (if $encode=1) or decodes text using substitution table-->
	<xsl:template name="encode-string">
		<xsl:param name="text"/>
		<xsl:param name="encodingTable"/>
		<xsl:param name="encodingElementIndex"/>
		<xsl:param name="encode"/>
		<xsl:choose>
			<xsl:when test="text='' or count($encodingTable//Symbol) &lt; $encodingElementIndex">
				<xsl:value-of select="$text"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="result">
					<xsl:choose>
						<xsl:when test="$encode = 1">
							<xsl:call-template name="replace-string">
								<xsl:with-param name="text" select="$text"/>
								<xsl:with-param name="replace" select="$encodingTable/Symbol[$encodingElementIndex]/@original"/>
								<xsl:with-param name="with" select="$encodingTable/Symbol[$encodingElementIndex]/@encoded"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="replace-string">
								<xsl:with-param name="text" select="$text"/>
								<xsl:with-param name="replace" select="$encodingTable/Symbol[$encodingElementIndex]/@encoded"/>
								<xsl:with-param name="with" select="$encodingTable/Symbol[$encodingElementIndex]/@original"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:call-template name="encode-string">
					<xsl:with-param name="text" select="$result" />
					<xsl:with-param name="encodingElementIndex" select="$encodingElementIndex+1"/>
					<xsl:with-param name="encodingTable" select="$encodingTable"/>
					<xsl:with-param name="encode" select="$encode"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--Replace string implementation-->
	<xsl:template name="replace-string">
		<xsl:param name="text"/>
		<xsl:param name="replace"/>
		<xsl:param name="with"/>
		<xsl:choose>
			<xsl:when test="contains($text,$replace)">
				<xsl:value-of select="substring-before($text,$replace)"/>
				<xsl:value-of select="$with"/>
				<xsl:call-template name="replace-string">
					<xsl:with-param name="text" select="substring-after($text,$replace)"/>
					<xsl:with-param name="replace" select="$replace"/>
					<xsl:with-param name="with" select="$with"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
