<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:q="http://schemas.quipt.com/api"
                xmlns:str="http://exslt.org/strings"
                xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl xsi xsd str q a">
	<xsl:output method="xml" indent="yes"/>

	<xsl:template match="q:InventoryVirtualResult" mode="ShippingDetails">
		<xsl:param name="postalCode"/>
		<xsl:param name="quantity"/>
		<ShippingDetails>
			<xsl:variable name="shippingType">
				<xsl:choose>
					<xsl:when test="count(q:Freight/q:Rates/q:FreightRateDetails.FreightRate/q:ServiceLevel[.='Ground' or .='ThreeDay' or .='OneDay' or .='Truck']) &gt;0 and normalize-space(q:Freight/q:FreightCollectionOption) != '' and normalize-space(q:Freight/q:FreightCollectionOption)!='ChannelAccount'and normalize-space(q:Freight/q:FreightCollectionOption)!='0'">Flat</xsl:when>
					<xsl:otherwise>Calculated</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<xsl:if test="$shippingType='Calculated'">

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

				<CalculatedShippingRate>
					<!--<InternationalPackagingHandlingCosts currencyID="CurrencyCodeType"> AmountType (double) </InternationalPackagingHandlingCosts>-->
					<MeasurementUnit>English</MeasurementUnit>
					<OriginatingPostalCode>
						<xsl:value-of select="$postalCode"/>
					</OriginatingPostalCode>
					<PackageDepth unit="in" measurementSystem="English">
						<xsl:value-of select="q:ShippingInfo/q:Dimensions/q:Height"/>
					</PackageDepth>
					<PackageLength unit="in" measurementSystem="English">
						<xsl:value-of select="q:ShippingInfo/q:Dimensions/q:Length"/>
					</PackageLength>
					<PackageWidth unit="in" measurementSystem="English">
						<xsl:value-of select="q:ShippingInfo/q:Dimensions/q:Width"/>
					</PackageWidth>
					<xsl:text>&#x0d;&#x0a;</xsl:text>
					<!--<PackagingHandlingCosts currencyID="CurrencyCodeType"> AmountType (double) </PackagingHandlingCosts>-->
					<ShippingIrregular>false</ShippingIrregular>
					<!--<ShippingPackage>None</ShippingPackage>-->
					<WeightMajor unit="lbs" measurementSystem="English">
						<xsl:value-of select="$weightMajor"/>
					</WeightMajor>
					<WeightMinor unit="oz" measurementSystem="English">
						<xsl:value-of select="$weightMinor"/>
					</WeightMinor>
				</CalculatedShippingRate>
				<xsl:text>&#x0d;&#x0a;</xsl:text>
				<!--<InsuranceOption>Optional</InsuranceOption>-->
				<!--Shipping Insurance Option Discontinued-->
			</xsl:if>
			<xsl:apply-templates select="current()" mode="shipOptions">
				<xsl:with-param name="shippingType" select="$shippingType"/>
				<xsl:with-param name="quantity" select="$quantity"/>
			</xsl:apply-templates>
			<ShippingType>
				<xsl:value-of select="$shippingType"/>
			</ShippingType>
		</ShippingDetails>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="shipOptions">
		<xsl:param name="shippingType" />
		<xsl:param name="quantity" />
		<!-- Reference http://developer.ebay.com/devzone/xml/docs/reference/ebay/additem.html for more details -->
		<!-- Upto 4 ShippingServiceOptions nodes allowed here -->
		<xsl:choose>
			<xsl:when test="$shippingType = 'Flat'">
				<xsl:call-template name="shippingOverride">
					<xsl:with-param name="servicelevelDescription">Ground</xsl:with-param>
					<xsl:with-param name="mapTo">ShippingMethodStandard</xsl:with-param>
					<xsl:with-param name="quantity" select="$quantity"/>
				</xsl:call-template>
				<xsl:call-template name="shippingOverride">
					<xsl:with-param name="servicelevelDescription">ThreeDay</xsl:with-param>
					<xsl:with-param name="mapTo">ShippingMethodExpress</xsl:with-param>
					<xsl:with-param name="quantity" select="$quantity"/>
				</xsl:call-template>
				<xsl:call-template name="shippingOverride">
					<xsl:with-param name="servicelevelDescription">OneDay</xsl:with-param>
					<xsl:with-param name="mapTo">ShippingMethodOvernight</xsl:with-param>
					<xsl:with-param name="quantity" select="$quantity"/>
				</xsl:call-template>
				<xsl:if test="not(q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:ServiceLevel = 'Ground'])">
					<xsl:call-template name="shippingOverride">
						<xsl:with-param name="servicelevelDescription">Truck</xsl:with-param>
						<xsl:with-param name="mapTo">FlatRateFreight</xsl:with-param>
						<xsl:with-param name="quantity" select="$quantity"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<ShippingServiceOptions>
					<FreeShipping>false</FreeShipping>
					<ShippingService>FedExHomeDelivery</ShippingService>
				</ShippingServiceOptions>
				<xsl:text>&#x0d;&#x0a;</xsl:text>
				<ShippingServiceOptions>
					<FreeShipping>false</FreeShipping>
					<ShippingService>FedExExpressSaver</ShippingService>
				</ShippingServiceOptions>
				<xsl:text>&#x0d;&#x0a;</xsl:text>
				<ShippingServiceOptions>
					<FreeShipping>false</FreeShipping>
					<ShippingService>FedEx2Day</ShippingService>
				</ShippingServiceOptions>
				<xsl:text>&#x0d;&#x0a;</xsl:text>
				<ShippingServiceOptions>
					<FreeShipping>false</FreeShipping>
					<ShippingService>FedExStandardOvernight</ShippingService>
				</ShippingServiceOptions>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:text>&#x0d;&#x0a;</xsl:text>
	</xsl:template>

	<xsl:template name="shippingOverride">
		<xsl:param name="servicelevelDescription"/>
		<xsl:param name="mapTo"/>
		<xsl:param name="quantity" />

		<xsl:variable name="rate">
			<xsl:call-template name="shipping-rate">
				<xsl:with-param name="servicelevelDescription" select="$servicelevelDescription"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:if test="normalize-space($rate)!=''">
			<ShippingServiceOptions>
				<FreeShipping>
					<xsl:choose>
						<xsl:when test="number($rate) = 0">true</xsl:when>
						<xsl:otherwise>false</xsl:otherwise>
					</xsl:choose>
				</FreeShipping>
				<ShippingService>
					<xsl:value-of select="$mapTo"/>
				</ShippingService>
				<xsl:if test="number($quantity) &gt; 1">
					<ShippingServiceAdditionalCost currencyID="USD">
						<xsl:value-of select="format-number($rate,'0.00')"/>
					</ShippingServiceAdditionalCost>
				</xsl:if>
				<ShippingServiceCost currencyID="USD">
					<xsl:value-of select="format-number($rate,'0.00')"/>
				</ShippingServiceCost>
			</ShippingServiceOptions>
			<xsl:text>&#x0d;&#x0a;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template name="shipping-rate">
		<xsl:param name="servicelevelDescription"/>
		<xsl:choose>
			<xsl:when test="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:ServiceLevel = $servicelevelDescription]/q:Included='true'">0</xsl:when>
			<xsl:when test="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:ServiceLevel = $servicelevelDescription]/q:Included='false' and number(q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:ServiceLevel = $servicelevelDescription]/q:Rate/q:Value) &gt;=0">
				<xsl:value-of select="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:ServiceLevel = $servicelevelDescription]/q:Rate/q:Value"/>
			</xsl:when>
			<xsl:otherwise>
				<!--Rate not found. Output nothing-->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>