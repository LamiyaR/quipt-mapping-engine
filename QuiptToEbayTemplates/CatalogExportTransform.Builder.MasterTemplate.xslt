<?xml version="1.0" encoding="utf-8"?>
<!-- All these xsl:stylesheet attributes should be defined in the 'axsl:stylesheet' element of CatalogExportTransform.Builder.xslt file. 
    For proper rendering all xsl:stylesheet attributes changes should be copied to 'axsl:stylesheet' element of Builder template. -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:q="http://schemas.quipt.com/api"
                xmlns:str="http://exslt.org/strings"
                xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl xsi xsd str q">

	<xsl:import href="str.split.template.xslt"/>
	<xsl:import href="join.template.xslt"/>
	<xsl:import href="encoding.template.xslt"/>
	<xsl:import href="MarketplacePriceSelector.xslt"/>
	<xsl:import href="InventoryExportTransform.Shared.xslt"/>
	<xsl:import href="inventory.shared.xslt" />

	<!--Partner specific CatalogExportTransform.Custom.xslt should be dynamically included to the end during catalog export-->

	<xsl:output method="xml" indent="yes"/>

	<xsl:key name="sections-by-name" match="q:Section" use="q:Name" />

	<xsl:param name="Mode"/>

	<xsl:param name="BypassFilter">1</xsl:param>
	<xsl:param name="Type">XML</xsl:param>
	<!-- Inventory location id. Required for inventory create request. Should be pulled from vendor settings and passed as xslt parameter. -->
	<xsl:param name="INVENTORYLOCID">LOCID</xsl:param>
	<!-- Default values to use if appropriate inventory property not initialized -->
	<xsl:param name="SHIPPOLICYDEF">SHIPPOL</xsl:param>
	<xsl:param name="RETURNPOLICYDEF">RETURNPOL</xsl:param>
	<xsl:param name="PAYMTPOLICYDEF">PAYMENTPOL</xsl:param>
	<xsl:param name="MAXQTY"/>
	<!-- 'True' if enabled -->
	<xsl:param name="VARIANT"/>

	<!-- Xml parameter. Expected xml format: 
      Key: COND_{QuiptConditionCode} - General override
      Key: COND_{QuiptConditionCode}_{QuiptCategoryId} - Category specific override
  <array><a key="COND_{QuiptConditionCode}_{QuiptCategoryId}" value="condition"/></array>-->
	<xsl:param name="COND"/>

	<!-- Xml parameter. If value=False - exclude. Expected xml format:
    <array>
    <a key="CERTREFURB_{MANID}_{CATID}" value="True"/>
    <a key="CERTREFURB_{MANID}_ALL" value="True"/>
    <a key="CERTREFURB_ALL_{CATID}" value="True"/>
</array>-->
	<xsl:param name="CERTREFURB2"/>
	<xsl:param name="SELLREFURB2"/>

	<xsl:param name="CERTREFURB"/>
	<xsl:param name="SELLREFURB"/>

	<xsl:variable name="CERTREFURB_UPR" select="translate($CERTREFURB,'abcdef','ABCDEF')"/>
	<xsl:variable name="SELLREFURB_UPR" select="translate($SELLREFURB,'abcdef','ABCDEF')"/>

	<xsl:variable name="newline" select="'&#x0d;&#x0a;'"/>

	<!-- TEST TEMPLATES BEGIN -->
	<!-- These templates are for master template testing only and can be removed.
  More specific templates will be appended by builder, so these dummy templates should not affect transformation results. -->
	<xsl:template match="*" mode="CategoryId">DummyCategoryId</xsl:template>
	<xsl:template match="*" mode="Condition">DummyCondition</xsl:template>

	<xsl:template match="*" mode="Filter">dummy filter (do not filter if template is not empty and produces any text)</xsl:template>

	<xsl:template match="*" mode="render-attributes">
		<xsl:call-template name="render-attribute">
			<xsl:with-param name="name">dummyAttributeId1</xsl:with-param>
			<xsl:with-param name="value">dummyValue1|dummyValue2</xsl:with-param>
		</xsl:call-template>
		<xsl:call-template name="render-attribute">
			<xsl:with-param name="name">dummyAttributeId2</xsl:with-param>
			<xsl:with-param name="value">dummyValue</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="*" mode="VariantAttributeMapping">
		<string quiptCode="GENERICCOLOR">Color</string>
	</xsl:template>
	<!-- TEST TEMPLATES END -->

	<!--Next dummy tempates may be overriden by partner-specific transform-->
	<xsl:template match="*" mode="inventory-description"/>
	<xsl:template match="*" mode="listing-description"/>
	<xsl:template match="*" mode="storeCategoryNames"/>

	<!-- Section to put attributes with empty section to -->
	<xsl:variable name="DefaultSectionName">General Information</xsl:variable>

	<!-- Default AttributesBySections implementation. Can be overriden in custom templates. -->
	<xsl:template match="*" mode ="AttributesBySections">

		<xsl:variable name="variantMapping">
			<xsl:if test="string($VARIANT)='True' and string(q:Summary/q:VariantKey)!=''">
				<xsl:apply-templates select="." mode="VariantAttributeMapping"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="variantMappingNodeSet" select="msxsl:node-set($variantMapping)"/>

		<!-- as description is shared between variants exclude variant attributes from the description -->
		<xsl:variable name="att">
			<xsl:for-each select="q:Catalog/q:Attributes/q:Attribute">
				<xsl:if test="not($variantMappingNodeSet/string[@quiptCode=current()/q:Code])">
					<xsl:copy-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="attr" select="msxsl:node-set($att)"/>

		<xsl:apply-templates select="." mode="Specs">
			<xsl:with-param name="attributes" select="$attr/q:Attribute[(q:Section = '' or normalize-space(q:Section/q:Name)='' or normalize-space(q:Section/q:Name) = normalize-space($DefaultSectionName)) and normalize-space(q:Value)!='']"/>
			<xsl:with-param name="header" select="$DefaultSectionName"/>
		</xsl:apply-templates>

		<xsl:for-each select="$attr/q:Attribute/q:Section[q:Name!='' and q:Name!=$DefaultSectionName and generate-id(.)=generate-id(key('sections-by-name',q:Name)[1])]">
			<xsl:variable name="sectionName" select ="q:Name"/>
			<xsl:apply-templates select="." mode="Specs">
				<xsl:with-param name="attributes" select="$attr/q:Attribute[q:Section/q:Name = $sectionName and normalize-space(q:Value)!='']"/>
				<xsl:with-param name="header" select="$sectionName"/>
			</xsl:apply-templates>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="*" mode="Specs">
		<xsl:param name="attributes"/>
		<xsl:param name="header"/>
		<xsl:if test ="$attributes!=''">
			<xsl:text>&lt;h3 style="margin:4px 0 4px 0;"&gt;</xsl:text>
			<xsl:value-of select="$header"/>
			<xsl:text>&lt;/h3&gt;&lt;ul style="clear:left;margin:0px 0px 10px 0;"&gt;</xsl:text>
			<xsl:for-each select="$attributes">
				<xsl:text>&lt;li&gt;&lt;span style="color:#666666;"&gt;</xsl:text>
				<xsl:value-of select="q:Name"/>
				<xsl:text>: </xsl:text>
				<xsl:variable name="value">
					<xsl:for-each select="q:Value/a:string">
						<xsl:if test="position() &gt; 1">
							<xsl:text>, </xsl:text>
						</xsl:if>
						<xsl:value-of select="normalize-space(.)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:text>&lt;/span&gt;</xsl:text>
				<xsl:value-of select="$value"/>
				<xsl:text>&lt;/li&gt;</xsl:text>
			</xsl:for-each>
			<xsl:text>&lt;/ul&gt;</xsl:text>
		</xsl:if>
	</xsl:template>

	<!-- Returns 1 or 0. Can be used in catalog mapper -->
	<xsl:template match="q:InventoryVirtualResult" mode="certRfb">
		<xsl:variable name="categoryId" select="translate(q:Catalog/q:Category/q:Id,'abcdef','ABCDEF')"/>
		<xsl:choose>
			<xsl:when test="contains($CERTREFURB_UPR,'ALL')">1</xsl:when>
			<xsl:when test="contains($CERTREFURB_UPR,$categoryId)">1</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="isCategoryCondition">
					<xsl:with-param name="prefix">CERTREFURB</xsl:with-param>
					<xsl:with-param name="xml" select="$CERTREFURB2"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Returns 1 or 0. Can be used in catalog mapper -->
	<xsl:template match="q:InventoryVirtualResult" mode="sellerRfb">
		<xsl:variable name="categoryId" select="translate(q:Catalog/q:Category/q:Id,'abcdef','ABCDEF')"/>
		<xsl:choose>
			<xsl:when test="contains($SELLREFURB_UPR,'ALL')">1</xsl:when>
			<xsl:when test="contains($SELLREFURB_UPR,$categoryId)">1</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="isCategoryCondition">
					<xsl:with-param name="prefix">SELLREFURB</xsl:with-param>
					<xsl:with-param name="xml" select="$SELLREFURB2"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match= "/q:SyncInventoryVirtualResults">
		<xsl:apply-templates select="." mode="shouldExport"/>
	</xsl:template>

	<xsl:template match="/q:ArrayOfInventoryVirtualResult">

		<xsl:variable name="items">
			<xsl:apply-templates select="q:InventoryVirtualResult" mode="generate"/>
		</xsl:variable>
		<xsl:if test="msxsl:node-set($items)/*">
			<xsl:choose>
				<xsl:when test="$Mode='Buybox'">
					<ArrayOfBuyboxRequest>
						<xsl:copy-of select="$items"/>
					</ArrayOfBuyboxRequest>
				</xsl:when>
				<xsl:when test="string($Mode)='GetCategoryId'">
					<CategoryBasedRequest>
						<xsl:copy-of select="$items"/>
					</CategoryBasedRequest>
				</xsl:when>
				<xsl:otherwise>
					<ArrayOfCatalogItem>
						<xsl:copy-of select="$items"/>
					</ArrayOfCatalogItem>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="GetCategoryId">
		<!-- Store additional data for troubleshooting. Only category is required. -->
		<FeedId>
			<xsl:value-of select="q:Id"/>
		</FeedId>
		<QuiptCategoryId>
			<xsl:value-of select="q:Catalog/q:Category/q:Id"/>
		</QuiptCategoryId>
		<Category>
			<xsl:apply-templates select="." mode="CategoryId" />
		</Category>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="ConditionOverride">
		<xsl:variable name="cond">
			<xsl:apply-templates select="." mode="COND"/>
		</xsl:variable>
		<xsl:variable name="catMapper">
			<xsl:apply-templates select="." mode="Condition"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="normalize-space($cond)!=''">
				<xsl:value-of select="$cond"/>
			</xsl:when>
			<xsl:when test="normalize-space($catMapper)!=''">
				<xsl:value-of select="$catMapper"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="certRfb">
					<xsl:apply-templates select="." mode="certRfb"/>
				</xsl:variable>
				<xsl:variable name="sellerRfb">
					<xsl:apply-templates select="." mode="sellerRfb"/>
				</xsl:variable>
				<xsl:variable name="isWarnProviderManu">
					<xsl:choose>
						<xsl:when test="q:Catalog/q:Warranty/q:Provider = 'Manufacturer'">1</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="q:Summary/q:Condition/q:Code = 'NEW'">NEW</xsl:when>
					<xsl:when test="q:Summary/q:Condition/q:Code = 'NOB'">NEW_OTHER</xsl:when>
					<!-- <xsl:when test="">NEW_WITH_DEFECTS</xsl:when> -->
					<xsl:when test="$certRfb=1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">CERTIFIED_REFURBISHED</xsl:when>
					<xsl:when test="$sellerRfb=1 and (q:Summary/q:Condition/q:Code = 'REFURBMAN' or q:Summary/q:Condition/q:Code = 'REFURB3RD' or q:Summary/q:Condition/q:Code = 'SCRADDNT')">SELLER_REFURBISHED</xsl:when>
					<!-- <xsl:when test="">LIKE_NEW</xsl:when> -->
					<xsl:when test="q:Summary/q:Condition/q:Code = 'REFURBMAN'">USED_EXCELLENT</xsl:when>
					<xsl:when test="q:Summary/q:Condition/q:Code = 'REFURB3RD'">USED_EXCELLENT</xsl:when>
					<xsl:when test="q:Summary/q:Condition/q:Code = 'USEDGD'">USED_EXCELLENT</xsl:when>
					<xsl:when test="q:Summary/q:Condition/q:Code = 'SCRADDNT'">USED_ACCEPTABLE</xsl:when>
					<!-- <xsl:when test="">USED_VERY_GOOD</xsl:when> -->
					<!-- <xsl:when test="">USED_GOOD</xsl:when> -->
					<!-- <xsl:when test="">USED_ACCEPTABLE</xsl:when> -->
					<!-- <xsl:when test="">FOR_PARTS_OR_NOT_WORKING</xsl:when> -->
					<xsl:otherwise>-1</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="Buybox">
		<BuyboxRequest xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
			<ConditionIds>
				<xsl:variable name="condition">
					<xsl:apply-templates select="." mode="ConditionOverride"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$condition = 'NEW'">1000</xsl:when>
					<xsl:when test="$condition = 'LIKE_NEW'">2750</xsl:when>
					<xsl:when test="$condition = 'NEW_OTHER'">1500</xsl:when>
					<xsl:when test="$condition = 'NEW_WITH_DEFECTS'">1750</xsl:when>
					<!--<xsl:when test="$condition = 'MANUFACTURER_REFURBISHED'"></xsl:when>-->
					<xsl:when test="$condition = 'CERTIFIED_REFURBISHED'">2000</xsl:when>
					<xsl:when test="$condition = 'SELLER_REFURBISHED'">2500</xsl:when>
					<xsl:when test="$condition = 'USED_EXCELLENT'">3000</xsl:when>
					<xsl:when test="$condition = 'USED_VERY_GOOD'">4000</xsl:when>
					<xsl:when test="$condition = 'USED_GOOD'">5000</xsl:when>
					<xsl:when test="$condition = 'USED_ACCEPTABLE'">6000</xsl:when>
					<xsl:when test="$condition = 'FOR_PARTS_OR_NOT_WORKING'">7000</xsl:when>
					<xsl:when test="$condition = 'EXCELLENT_REFURBISHED'">2010</xsl:when>
					<xsl:when test="$condition = 'VERY_GOOD_REFURBISHED'">2020</xsl:when>
					<xsl:when test="$condition = 'GOOD_REFURBISHED'">2030</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$condition"/>
					</xsl:otherwise>
				</xsl:choose>
			</ConditionIds>
			<xsl:variable name="freight" select="number(q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:ServiceLevel = 'Ground']/q:Rate/q:Value)"/>
			<xsl:if test="number($freight)&gt;=0">
				<Freight>
					<xsl:value-of select="format-number($freight,'0.00')"/>
				</Freight>
			</xsl:if>
			<SKU>
				<xsl:value-of select="q:Summary/q:SKU" />
			</SKU>
			<UPC>
				<xsl:value-of select="normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='UPC']/q:Value)" />
			</UPC>
		</BuyboxRequest>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="generate">
		<xsl:choose>
			<xsl:when test="normalize-space($BypassFilter) != ''">
				<xsl:apply-templates select="." mode="render"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="shouldExport">
					<xsl:apply-templates select="." mode="Filter"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="normalize-space($shouldExport)!='' and $Mode='Buybox'">
						<xsl:apply-templates select="." mode="Buybox"/>
					</xsl:when>
					<xsl:when test="(normalize-space($shouldExport)!='' or string(q:Summary/q:SKU)='') and string($Mode)='GetCategoryId'">
						<xsl:apply-templates select="." mode="GetCategoryId"/>
					</xsl:when>
					<xsl:when test="normalize-space($shouldExport)!=''">
						<xsl:apply-templates select="." mode="render"/>
					</xsl:when>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="render">
		<xsl:variable name="categoryId">
			<xsl:apply-templates select="." mode="CategoryId"/>
		</xsl:variable>

		<xsl:variable name="weight">
			<xsl:value-of select="q:ShippingInfo/q:Weight/q:Value"/>
		</xsl:variable>

		<xsl:variable name="weightMajor">
			<xsl:value-of select="format-number($weight, '0')"/>
		</xsl:variable>

		<xsl:variable name="weightMinorStep1">
			<!-- get value after decimal point -->
			<xsl:value-of select="number(format-number($weight, '0'))-$weight"/>
		</xsl:variable>
		<xsl:variable name="weightMinorStep2">
			<!-- perform ABS -->
			<xsl:value-of select="($weightMinorStep1 >= 0)*$weightMinorStep1 - not($weightMinorStep1 >= 0)*$weightMinorStep1"/>
		</xsl:variable>
		<xsl:variable name="weightMinor">
			<!-- get oz value -->
			<xsl:value-of select="format-number($weightMinorStep2*16, '0')"/>
		</xsl:variable>

		<xsl:variable name="quantity">
			<xsl:variable name="calcQty">
				<xsl:apply-templates select="current()" mode="quantity"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$calcQty &gt; number(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'MAXQTY']/q:Value)">
					<xsl:value-of select="format-number(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'MAXQTY']/q:Value,'0')"/>
				</xsl:when>
				<xsl:when test="$calcQty &gt; $MAXQTY">
					<xsl:value-of select="$MAXQTY"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$calcQty"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="price">
			<xsl:apply-templates select="current()" mode="pricing"/>
		</xsl:variable>

		<xsl:variable name="sku">
			<xsl:value-of select="normalize-space(q:Summary/q:SKU)"/>
		</xsl:variable>
		<xsl:variable name="aspects">
			<xsl:apply-templates select="." mode="render-attributes"/>
		</xsl:variable>
		<xsl:variable name="aspectsNodeSet" select="msxsl:node-set($aspects)"/>
		<xsl:variable name="duplicateAspects">
			<xsl:for-each select="$aspectsNodeSet/a:KeyValueOfstringArrayOfstringty7Ep6D1">
				<xsl:if test="preceding-sibling::a:KeyValueOfstringArrayOfstringty7Ep6D1[a:Key = current()/a:Key]">
					<a>
						<xsl:value-of select="a:Key"/>
					</a>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="exportError">
			<xsl:if test="msxsl:node-set($duplicateAspects)/a">
				<xsl:text>Duplicate aspect (</xsl:text>
				<xsl:for-each select="msxsl:node-set($duplicateAspects)/a">
					<xsl:value-of select="."/>
					<xsl:if test="position()!=last()">, </xsl:if>
				</xsl:for-each>
				<xsl:text>) found.</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="conditionDescription">
			<xsl:apply-templates select="." mode="conditionDescription"/>
		</xsl:variable>
		<xsl:variable name="listingDescription">
			<xsl:apply-templates select="." mode="listing-description"/>
		</xsl:variable>

		<xsl:variable name="variantMapping">
			<xsl:if test="string($VARIANT)='True' and string(q:Summary/q:VariantKey)!=''">
				<xsl:apply-templates select="." mode="VariantAttributeMapping"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="variantMappingNodeSet" select="msxsl:node-set($variantMapping)"/>
		<!-- ***************************************************************************** -->
		<CatalogItem>
			<xsl:if test="normalize-space($exportError)!=''">
				<ExportError>
					<xsl:value-of select="$exportError"/>
				</ExportError>
			</xsl:if>
			<!--<Epid>
        <xsl:if test="normalize-space(q:MapId)!=''">
          <xsl:value-of select="normalize-space(q:MapId)"/>
        </xsl:if>      
      </Epid>-->
			<InventoryCreateRequest>
				<availability>
					<!--<pickupAtLocationAvailability i:nil="true"/>-->
					<shipToLocationAvailability>
						<quantity>
							<xsl:value-of select="$quantity"/>
						</quantity>
					</shipToLocationAvailability>
				</availability>
				<!--
         NEW
This enumeration value indicates that the inventory item is a brand-new, unopened item in its original packaging. This enumeration value should be used if the Condition ID value is 1000. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
LIKE_NEW
This enumeration value indicates that the inventory item is in 'like-new' condition. In other words, the item has been opened, but very lightly used if used at all. This condition typically applies to books or DVDs. This enumeration value should be used if the Condition ID value is 2750. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
NEW_OTHER
This enumeration value indicates that the inventory item is a new, unused item, but it may be missing the original packaging or perhaps not sealed. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 1500. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
NEW_WITH_DEFECTS
This enumeration value indicates that the inventory item is a new, unused item, but it has defects. This item condition is typically applicable to clothing or shoes that may have scuffs, hanging threads, missing buttons, etc. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 1750. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
MANUFACTURER_REFURBISHED
This enumeration value should no longer be used, as the 'Manufacturer Refurbished' item condition is no longer a valid item condition on any eBay marketplace.

Note: In all eBay marketplaces, Condition ID 2000 now maps to an item condition of 'Certified Refurbished', and not 'Manufacturer Refurbished'. Since the launch of 'Certified Refurbished', this MANUFACTURER_REFURBISHED enum value has been used to set the item condition to 'Certified Refurbished', but with the introduction of the CERTIFIED_REFURBISHED value in Version 1.13.0, this MANUFACTURER_REFURBISHED enum is no longer applicable. For the time being, if the MANUFACTURER_REFURBISHED enum is used, it will be accepted but automatically converted by eBay to CERTIFIED_REFURBISHED. In the future, the MANUFACTURER_REFURBISHED may start triggering an error if used.
CERTIFIED_REFURBISHED
This enumeration value indicates that the inventory item is in pristine, like-new condition and has been inspected, cleaned and refurbished by the manufacturer or a manufacturer-approved vendor. The item will be in new packaging with original or new accessories. This enumeration value should be used if the Condition ID value is 2000. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.

Note: This CERTIFIED_REFURBISHED value has replaced the deprecated MANUFACTURER_REFURBISHED value. eBay will automatically convert the condition value of existing inventory items from MANUFACTURER_REFURBISHED to CERTIFIED_REFURBISHED. To list an item as 'Certified Refurbished', a seller must be pre-qualified by eBay for this feature. Any seller who is not eligible for this feature will be blocked if they try to create a new listing or revise an existing listing with this item condition.

Any seller that is interested in eligibility requirements to list with 'Certified Refurbished' should see the Certified refurbished program page in Seller Center.
SELLER_REFURBISHED
This enumeration value indicates that the inventory item has been restored to working order by the eBay seller or a third party. This means the item was inspected, cleaned, and repaired to full working order and is in excellent condition. This item may or may not be in original packaging. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 2500. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
USED_EXCELLENT
This enumeration value indicates that the inventory item is used but in excellent condition. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 3000. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
USED_VERY_GOOD
This enumeration value indicates that the inventory item is used but in very good condition. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 4000. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
USED_GOOD
This enumeration value indicates that the inventory item is used but in good condition. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 5000. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
USED_ACCEPTABLE
This enumeration value indicates that the inventory item is in acceptable condition. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 6000. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.
FOR_PARTS_OR_NOT_WORKING
This enumeration value indicates that the inventory item is not fully functioning as originally designed. A buyer will generally buy an item in this condition knowing that the item will need to be repaired, or a buyer will buy that item just to use one or more of the parts/components that comprise the item. When a seller specifies this condition for an item, that seller should also provide a more detailed explanation of the item's condition in the conditionDescription field. This enumeration value should be used if the Condition ID value is 7000. Condition ID values are used in both the Trading and Metadata APIs to indicate item condition.          -->
				<condition>
					<xsl:variable name="condition">
						<xsl:apply-templates select="." mode="ConditionOverride"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$condition = '1000'">NEW</xsl:when>
						<xsl:when test="$condition = '2750'">LIKE_NEW</xsl:when>
						<xsl:when test="$condition = '1500'">NEW_OTHER</xsl:when>
						<xsl:when test="$condition = '1750'">NEW_WITH_DEFECTS</xsl:when>
						<!--<xsl:when test="$condition = ''">MANUFACTURER_REFURBISHED</xsl:when>-->
						<xsl:when test="$condition = '2000'">CERTIFIED_REFURBISHED</xsl:when>
						<xsl:when test="$condition = '2500'">SELLER_REFURBISHED</xsl:when>
						<xsl:when test="$condition = '3000'">USED_EXCELLENT</xsl:when>
						<xsl:when test="$condition = '4000'">USED_VERY_GOOD</xsl:when>
						<xsl:when test="$condition = '5000'">USED_GOOD</xsl:when>
						<xsl:when test="$condition = '6000'">USED_ACCEPTABLE</xsl:when>
						<xsl:when test="$condition = '7000'">FOR_PARTS_OR_NOT_WORKING</xsl:when>
						<xsl:when test="$condition = '2010'">EXCELLENT_REFURBISHED</xsl:when>
						<xsl:when test="$condition = '2020'">VERY_GOOD_REFURBISHED</xsl:when>
						<xsl:when test="$condition = '2030'">GOOD_REFURBISHED</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$condition"/>
						</xsl:otherwise>
					</xsl:choose>
				</condition>
				<xsl:if test="normalize-space($conditionDescription)!=''">
					<conditionDescription>
						<xsl:value-of select ="normalize-space($conditionDescription)"/>
					</conditionDescription>
				</xsl:if>
				<locale>en_US</locale>
				<packageWeightAndSize>
					<dimensions>
						<height>
							<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Height, '0.0')"/>
						</height>
						<length>
							<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Length, '0.0')"/>
						</length>
						<unit>
							<xsl:choose>
								<xsl:when test="normalize-space(q:ShippingInfo/q:Dimensions/q:Units) = 'IN'">INCH</xsl:when>
								<xsl:when test="normalize-space(q:ShippingInfo/q:Dimensions/q:Units) = 'CM'">CENTIMETER</xsl:when>
							</xsl:choose>
						</unit>
						<width>
							<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Width, '0.0')"/>
						</width>
					</dimensions>
					<!--<packageType>MAILING_BOX</packageType>-->
					<weight>
						<unit>
							<xsl:choose>
								<xsl:when test="normalize-space(q:ShippingInfo/q:Weight/q:Units)='Pounds'">POUND</xsl:when>
								<xsl:when test="normalize-space(q:ShippingInfo/q:Weight/q:Units)='Grams'">GRAM</xsl:when>
								<xsl:when test="normalize-space(q:ShippingInfo/q:Weight/q:Units)='Kilograms'">KILOGRAM</xsl:when>
							</xsl:choose>
						</unit>
						<value>
							<xsl:value-of select="format-number(q:ShippingInfo/q:Weight/q:Value, '0.00')"/>
						</value>
					</weight>
				</packageWeightAndSize>
				<product>
					<aspects>
						<xsl:for-each select="$aspectsNodeSet/a:KeyValueOfstringArrayOfstringty7Ep6D1">
							<xsl:if test="not(preceding-sibling::a:KeyValueOfstringArrayOfstringty7Ep6D1[a:Key = current()/a:Key])">
								<xsl:copy-of select="."/>
							</xsl:if>
						</xsl:for-each>
					</aspects>
					<brand>
						<xsl:value-of select="normalize-space(q:Catalog/q:Brand/q:Name)"/>
					</brand>
					<!--<xsl:variable name="inventoryDescription">
            <xsl:apply-templates select="." mode="inventory-description"/>
          </xsl:variable>
          <xsl:if test="normalize-space($inventoryDescription)!=''">-->
					<description>
						<xsl:call-template name="replace-string">
							<xsl:with-param name="text" select="q:Catalog/q:Description"/>
							<xsl:with-param name="replace">Certified Refurbished</xsl:with-param>
							<xsl:with-param name="with">Refurbished</xsl:with-param>
						</xsl:call-template>
						<xsl:if test="normalize-space($listingDescription)=''">
							<xsl:if test="normalize-space($conditionDescription)!=''">
								<xsl:value-of select="concat(' ',normalize-space($conditionDescription))"/>
							</xsl:if>
						</xsl:if>
						<!--<xsl:call-template name="replace-string">
                <xsl:with-param name="text" select="$inventoryDescription"/>
                <xsl:with-param name="replace">Certified Refurbished</xsl:with-param>
                <xsl:with-param name="with">Refurbished</xsl:with-param>
              </xsl:call-template>-->
					</description>
					<!--</xsl:if>-->
					<!--<ean i:nil="true"/>-->
					<!-- Supported MapId format: p<ePid> or <ePid>: -->
					<xsl:variable name="epid">
						<xsl:choose>
							<!-- p{epid} -->
							<xsl:when test="normalize-space(q:MapId)!='' and substring(q:MapId,1,1)='p' and not(contains(q:MapId, ':'))">
								<xsl:value-of select="substring-after(q:MapId,'p')"/>
							</xsl:when>
							<!-- p{epid:offerid} -->
							<xsl:when test="normalize-space(q:MapId)!='' and substring(q:MapId,1,1)='p' and contains(q:MapId, ':')">
								<xsl:value-of select="substring-after(substring-before(q:MapId,':'),'p')"/>
							</xsl:when>
							<!-- {epid:offerid} -->
							<xsl:when test="normalize-space(q:MapId)!='' and substring(q:MapId,1,1)!='p' and contains(q:MapId, ':')">
								<xsl:value-of select="substring-before(q:MapId,':')"/>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="normalize-space($epid)!=''">
						<epid>
							<xsl:value-of select="normalize-space($epid)"/>
						</epid>
					</xsl:if>

					<xsl:variable name="images">
						<xsl:apply-templates select="q:Catalog" mode="images"/>
					</xsl:variable>
					<xsl:variable name="image-frag" select="msxsl:node-set($images)"/>

					<imageUrls>
						<xsl:if test="$image-frag/image[@type='primary'] != ''">
							<a:string>
								<xsl:value-of select="$image-frag/image[@type='primary']"/>
							</a:string>
						</xsl:if>
						<xsl:for-each select="$image-frag/image[@type='secondary' and position() &lt; 12]">
							<a:string>
								<xsl:value-of select="."/>
							</a:string>
						</xsl:for-each>
					</imageUrls>
					<!--<isbn i:nil="true"/>-->
					<mpn>
						<xsl:value-of select="normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='MPN']/q:Value)" />
					</mpn>
					<!--<subtitle i:nil="true"/>-->
					<title>
						<xsl:choose>
							<xsl:when test="normalize-space(q:Catalog/q:AltTitle2) != ''">
								<xsl:value-of select="normalize-space(q:Catalog/q:AltTitle2)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="normalize-space(q:Catalog/q:AltTitle)"/>
							</xsl:otherwise>
						</xsl:choose>
					</title>
					<upc>
						<a:string>
							<xsl:value-of select="normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='UPC']/q:Value)" />
						</a:string>
					</upc>
				</product>
				<sku>
					<xsl:value-of select="$sku"/>
				</sku>
			</InventoryCreateRequest>
			<!-- {listingId} to migrate -->
			<xsl:if test="normalize-space(q:MapId)!='' and not(substring(normalize-space(q:MapId),1,1)='p') and not(contains(q:MapId,':'))">
				<MigrateListingRequest>
					<listingId>
						<xsl:value-of select="normalize-space(q:MapId)"/>
					</listingId>
				</MigrateListingRequest>
			</xsl:if>

			<OfferCreateRequest>
				<!--<availableQuantity>
          <xsl:value-of select="$quantity"/>
        </availableQuantity>-->
				<categoryId>
					<xsl:value-of select="$categoryId"/>
				</categoryId>
				<format>FIXED_PRICE</format>

				<xsl:if test="normalize-space($listingDescription)!=''">
					<listingDescription>
						<xsl:call-template name="replace-string">
							<xsl:with-param name="text" select="$listingDescription"/>
							<xsl:with-param name="replace">Certified Refurbished</xsl:with-param>
							<xsl:with-param name="with">Refurbished</xsl:with-param>
						</xsl:call-template>
						<xsl:if test="normalize-space($conditionDescription)!=''">
							<xsl:value-of select="concat(' ',normalize-space($conditionDescription))"/>
						</xsl:if>
					</listingDescription>
				</xsl:if>
				<listingPolicies>
					<bestOfferTerms>
						<xsl:variable name="BO">
							<xsl:call-template name="getPropertyOrDefault">
								<xsl:with-param name="code">BO</xsl:with-param>
								<xsl:with-param name="defaultValue" select="No"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="BOACC">
							<xsl:call-template name="getPropertyOrDefault">
								<xsl:with-param name="code">BOACC</xsl:with-param>
								<xsl:with-param name="defaultValue"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="BOREJ">
							<xsl:call-template name="getPropertyOrDefault">
								<xsl:with-param name="code">BOREJ</xsl:with-param>
								<xsl:with-param name="defaultValue"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:if test="number($BOACC)&gt;=0">
							<autoAcceptPrice>
								<currency>USD</currency>
								<value>
									<xsl:value-of select="format-number($BOACC,'0.00')"/>
								</value>
							</autoAcceptPrice>
						</xsl:if>
						<xsl:if test="number($BOREJ)&gt;=0">
							<autoDeclinePrice>
								<currency>USD</currency>
								<value>
									<xsl:value-of select="format-number($BOREJ,'0.00')"/>
								</value>
							</autoDeclinePrice>
						</xsl:if>
						<bestOfferEnabled>
							<xsl:choose>
								<xsl:when test="translate($BO,'yes','YES')='YES'">true</xsl:when>
								<xsl:otherwise>false</xsl:otherwise>
							</xsl:choose>
						</bestOfferEnabled>
					</bestOfferTerms>
					<!--<ebayPlusIfEligible i:nil="true"/>-->
					<fulfillmentPolicyId>
						<xsl:call-template name="getPropertyOrDefault">
							<xsl:with-param name="code">SHIPPOLICY</xsl:with-param>
							<xsl:with-param name="defaultValue" select="$SHIPPOLICYDEF"/>
						</xsl:call-template>
					</fulfillmentPolicyId>
					<paymentPolicyId>
						<xsl:call-template name="getPropertyOrDefault">
							<xsl:with-param name="code">PAYMTPOLICY</xsl:with-param>
							<xsl:with-param name="defaultValue" select="$PAYMTPOLICYDEF"/>
						</xsl:call-template>
					</paymentPolicyId>
					<returnPolicyId>
						<xsl:call-template name="getPropertyOrDefault">
							<xsl:with-param name="code">RETURNPOLICY</xsl:with-param>
							<xsl:with-param name="defaultValue" select="$RETURNPOLICYDEF"/>
						</xsl:call-template>
					</returnPolicyId>
					<shippingCostOverrides i:nil="true"/>
				</listingPolicies>
				<lotSize i:nil="true"/>
				<marketplaceId>EBAY_US</marketplaceId>
				<merchantLocationKey>
					<xsl:value-of select="normalize-space($INVENTORYLOCID)"/>
				</merchantLocationKey>
				<pricingSummary>
					<minimumAdvertisedPrice i:nil="true"/>
					<originalRetailPrice>
						<currency>
							<xsl:value-of select="normalize-space(q:Catalog/q:Pricing/q:MSRP/q:Units)"/>
						</currency>
						<value>
							<xsl:value-of select="format-number(q:Catalog/q:Pricing/q:MSRP/q:Value, '0.00')"/>
						</value>
					</originalRetailPrice>
					<originallySoldForRetailPriceOn i:nil="true"/>
					<price>
						<currency>
							<xsl:value-of select="normalize-space(q:Catalog/q:Pricing/q:MSRP/q:Units)"/>
						</currency>
						<value>
							<xsl:value-of select="$price"/>
						</value>
					</price>
					<!--<pricingVisibility i:nil="true"/>-->
				</pricingSummary>
				<!--<quantityLimitPerBuyer>10</quantityLimitPerBuyer>-->
				<sku>
					<xsl:value-of select="$sku"/>
				</sku>
				<storeCategoryNames>
					<xsl:apply-templates select="." mode="storeCategoryNames"/>
				</storeCategoryNames>
				<!--<tax>
          <applyTax>True</applyTax>
          <thirdPartyTaxCategory>Electronics</thirdPartyTaxCategory>
          <vatPercentage>10.2</vatPercentage>
        </tax>-->
			</OfferCreateRequest>
			<xsl:if test="$variantMappingNodeSet/string">
				<Variant>
					<Request>
						<aspects>
							<xsl:for-each select="$aspectsNodeSet/a:KeyValueOfstringArrayOfstringty7Ep6D1">
								<xsl:if test="not(preceding-sibling::a:KeyValueOfstringArrayOfstringty7Ep6D1[a:Key = current()/a:Key]) and not($variantMappingNodeSet/string[string(.)=string(current()/a:Key)])">
									<xsl:copy-of select="."/>
								</xsl:if>
							</xsl:for-each>
						</aspects>
						<description>
							<xsl:call-template name="replace-string">
								<xsl:with-param name="text" select="$listingDescription"/>
								<xsl:with-param name="replace">Certified Refurbished</xsl:with-param>
								<xsl:with-param name="with">Refurbished</xsl:with-param>
							</xsl:call-template>
							<xsl:if test="normalize-space($conditionDescription)!=''">
								<xsl:value-of select="concat(' ',normalize-space($conditionDescription))"/>
							</xsl:if>
						</description>
						<xsl:variable name="images">
							<xsl:apply-templates select="q:Catalog" mode="swatch-images">
								<xsl:with-param name="https">1</xsl:with-param>
							</xsl:apply-templates>
						</xsl:variable>
						<xsl:variable name="image-frag" select="msxsl:node-set($images)" />
						<imageUrls>
							<xsl:for-each select="$variantMappingNodeSet/string">
								<xsl:variable name="img" select="$image-frag/image[@type=current()/@quiptCode and $aspectsNodeSet/a:KeyValueOfstringArrayOfstringty7Ep6D1[a:Key=string(current())]]"/>
								<xsl:if test="string($img)!=''">
									<a:string>
										<xsl:value-of select="$img"/>
									</a:string>
								</xsl:if>
							</xsl:for-each>
						</imageUrls>
						<title>
							<xsl:choose>
								<xsl:when test="normalize-space(q:Catalog/q:AltTitle2) != ''">
									<xsl:value-of select="normalize-space(q:Catalog/q:AltTitle2)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="normalize-space(q:Catalog/q:AltTitle)"/>
								</xsl:otherwise>
							</xsl:choose>
						</title>
						<variantSKUs>
							<a:string>
								<xsl:value-of select="q:Summary/q:SKU" />
							</a:string>
						</variantSKUs>
						<variesBy>
							<aspectsImageVariesBy>
								<xsl:for-each select="$variantMappingNodeSet/string">
									<xsl:if test="$aspectsNodeSet/a:KeyValueOfstringArrayOfstringty7Ep6D1[a:Key=string(current())]">
										<a:string>
											<xsl:value-of select="."/>
										</a:string>
									</xsl:if>
								</xsl:for-each>
							</aspectsImageVariesBy>
							<specifications>
								<xsl:for-each select="$variantMappingNodeSet/string">
									<xsl:if test="$aspectsNodeSet/a:KeyValueOfstringArrayOfstringty7Ep6D1[a:Key=string(current())]">
										<Specification>
											<name>
												<xsl:value-of select="."/>
											</name>
											<values>
												<xsl:for-each select="$aspectsNodeSet/a:KeyValueOfstringArrayOfstringty7Ep6D1[a:Key=string(current())]/a:Value/a:string">
													<a:string>
														<xsl:value-of select="."/>
													</a:string>
												</xsl:for-each>
											</values>
										</Specification>
									</xsl:if>
								</xsl:for-each>
							</specifications>
						</variesBy>
					</Request>
					<VariantKey>
						<xsl:value-of select="q:Summary/q:VariantKey"/>
					</VariantKey>
				</Variant>
			</xsl:if>
		</CatalogItem>
	</xsl:template>

	<xsl:template name="getPropertyOrDefault">
		<xsl:param name="code"/>
		<xsl:param name="defaultValue"/>
		<xsl:choose>
			<xsl:when test="normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = $code]/q:Value)!=''">
				<xsl:value-of select="normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = $code]/q:Value)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space($defaultValue)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="render-attribute">
		<xsl:param name="name"/>
		<!-- pipe separated Value1|Value2... (pipe is optional)-->
		<xsl:param name="value"/>

		<xsl:variable name="values">
			<xsl:call-template name="str:split">
				<xsl:with-param name="string" select="$value"/>
				<xsl:with-param name="pattern" select="'|'" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="valuesNodeSet" select="msxsl:node-set($values)" />

		<xsl:if test="normalize-space($value) != ''">
			<a:KeyValueOfstringArrayOfstringty7Ep6D1>
				<a:Key>
					<xsl:value-of select="normalize-space($name)"/>
				</a:Key>
				<a:Value>
					<xsl:for-each select="$valuesNodeSet/token">
						<a:string>
							<xsl:value-of select="normalize-space(.)"/>
						</a:string>
					</xsl:for-each>
				</a:Value>
			</a:KeyValueOfstringArrayOfstringty7Ep6D1>
		</xsl:if>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="conditionDescription">
		<xsl:variable name="r2v3">
			<xsl:value-of select="substring-after(q:Summary/q:Notes,'#r2v3')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="contains($r2v3,'#')">
				<xsl:value-of select="substring-before($r2v3,'#')"/>
			</xsl:when>
			<xsl:when test="contains($r2v3, '&#10;')">
				<!-- workaround as substring-before '&#10;' does not work -->
				<xsl:variable name="temp" select="translate($r2v3, '&#10;', '#')" />
				<xsl:value-of select="substring-before($temp, '#')" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space($r2v3)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="*" mode="quantity">
		<xsl:variable name="calcQty">
			<xsl:apply-templates select="." mode="qty"/>
		</xsl:variable>
		<xsl:value-of select="$calcQty"/>
	</xsl:template>
	<!-- End of shared part of .MasterTemplate. Templates below are category-specific and were auto-generated by Builder template. -->
</xsl:stylesheet>
