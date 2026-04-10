<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:q="http://schemas.quipt.com/api"
                xmlns:str="http://exslt.org/strings"
                xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl xsi xsd str q">
  <xsl:import href="..\inventory.shared.xslt" />
  <xsl:output method="xml" indent="yes"/>
  
  <!--This transform should be included in catalog export to render partner-specific fields.-->



  <xsl:template match="q:InventoryVirtualResult" mode="listing-description">
    <xsl:variable name="featuresResult">
      <xsl:apply-templates select="." mode="features"/>
    </xsl:variable>
    <xsl:variable name="features" select="msxsl:node-set($featuresResult)"/>
    &lt;!-- Begin Description --&gt;&lt;style&gt;

    &lt;!--
    div.ebay-adv{font-family:Verdana,san-serif;font-size:13px;line-height:19px;margin:10px;color:#333333; position: relative;}
    div.ebay-adv .thumbnail{position:relative;z-index:0;margin:5px;}
    div.ebay-adv .chxview{
    display:none;
    right:200px;
    top:0px;
    position:absolute;
    padding:0px;
    z-index:50;
    -webkit-box-shadow: 0 5px 24px rgba(0,0,0,0.5);
    -moz-box-shadow: 0 5px 24px rgba(0,0,0,0.5);
    box-shadow: 0 5px 24px rgba(0,0,0,0.5);
    }

    div.ebay-adv ul {
    list-style:square;
    padding-left:22px;
    }

    div.ebay-adv a {
    color:#f26531;
    }

    div.ebay-adv .returns {
    background-color:#e7e7e7;
    padding:25px 20px 20px;
    -webkit-border-radius: 5px;
    -moz-border-radius: 5px;
    border-radius: 5px;
    }
    //--&gt;

    &lt;/style&gt;
    &lt;div class="ebay-adv"&gt;
    &lt;div&gt;
    &lt;!-- &lt;div style="font-size:14px;color:#bababa;margin:2px 2px 0px 0px;clear:left;"&gt;(p/n: <xsl:value-of select="Catalog/SKUs/SKU[Type='MPN']/Value"/>)&lt;/div&gt; --&gt;
    &lt;/div&gt;
    &lt;div style="text-align:justify;padding:5px;margin:0px 0px 20px 0px;"&gt;<xsl:call-template name="break">
      <xsl:with-param name="text" select="q:Catalog/q:Description"/>
      <xsl:with-param name="replace" select="'&#10;'"/>
    </xsl:call-template>&lt;/div&gt;
    <xsl:if test="$features/a:string">
      &lt;div style="margin:0 0 25px 0;"&gt;&lt;img src="https://s3-us-west-2.amazonaws.com/quipt-images/eBay/h2-details.gif" alt="Details" style="margin:0 0 7px 0;"&gt;&lt;ul style="clear:left;margin:0px 0px 0px 0;"&gt;
      <xsl:apply-templates select="$features/a:string"/>
      &lt;/ul&gt;
      &lt;/div&gt;
    </xsl:if>
    &lt;!-- NEW CONTENT --&gt;
    &lt;div style="margin:0 0 25px 0;"&gt;&lt;img src="https://s3-us-west-2.amazonaws.com/quipt-images/eBay/h2-specifications.gif" alt="Specifications" style="margin:0 0 7px 0;"&gt;
    <xsl:apply-templates select="." mode="AttributesBySections"/>
    &lt;/div&gt;
    &lt;!-- END NEW CONTENT --&gt;

    <xsl:if test="q:Catalog/q:InBox">
      &lt;div style="margin:0 0 25px 0;"&gt;&lt;img src="https://s3-us-west-2.amazonaws.com/quipt-images/eBay/h2-package-contents.gif" alt="Package Contents" style="margin:0 0 7px 0;"&gt;&lt;ul style="clear:left;margin:0px 0px 0px 0;"&gt;
      <xsl:apply-templates select="q:Catalog/q:InBox"/>
      &lt;/ul&gt;
      &lt;/div&gt;
    </xsl:if>

    &lt;div class="returns"&gt;
    &lt;div style="margin:0 0 25px 0;"&gt;&lt;img src="https://s3-us-west-2.amazonaws.com/quipt-images/eBay/h2-warranty-grey.gif" alt="Warranty" style="margin:0 0 7px 0;"&gt;
    &lt;ul style="clear:left;margin:0px 0px 0px 0; list-style:none; padding-left:0;"&gt;
    &lt;li&gt;<xsl:choose>
      <xsl:when test="q:Catalog/q:Warranty/q:Provider = 'None'">AS IS. No warranty.</xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="q:Catalog/q:Warranty/q:Provider = 'Manufacturer'">Manufacturer</xsl:when>
          <xsl:otherwise>Distributor</xsl:otherwise>
        </xsl:choose><xsl:text>&#xa0;</xsl:text><xsl:value-of select="q:Catalog/q:Warranty/q:Duration"/>&lt;/li&gt;
      </xsl:otherwise>
    </xsl:choose>&lt;/li&gt;
    &lt;/ul&gt;
    &lt;/div&gt;
    &lt;div style="margin:0 0 25px 0;"&gt;&lt;img src="https://s3-us-west-2.amazonaws.com/quipt-images/eBay/h2-return-policy.gif" alt="Return Policy" style="margin:0 0 7px 0;"&gt;&lt;div style="clear:left;margin:5px 0px 5px 0px;"&gt;If you are not 100% satisfied with your purchase and/or if the item(s) received do not match the description provided, you can return your order for a full refund or replacement within 30 days from the date of purchase.&lt;/div&gt;
    &lt;/div&gt;
    &lt;div style="margin:0 0 10px 0;"&gt;&lt;img src="https://s3-us-west-2.amazonaws.com/quipt-images/eBay/h2-customer-service.gif" alt="Customer Service" style="margin:0 0 7px 0;"&gt;&lt;div style="clear:left;margin:5px 0px 5px 0px;"&gt;
    If you have any questions about an item, our policies or need help placing an order feel free to contact us.
    &lt;/div&gt;
    &lt;/div&gt;
    &lt;/div&gt;
    &lt;/div&gt;
    &lt;div style="color:#ffffff"&gt;37758&lt;/div&gt;
    &lt;/div&gt;
    <xsl:text>&#x0d;&#x0a;</xsl:text>
  </xsl:template>

  <xsl:template match="a:string">
    <xsl:text>&lt;li&gt;</xsl:text>
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="."/>
        <xsl:with-param name="replace">Certified Refurbished</xsl:with-param>
        <xsl:with-param name="with">Refurbished</xsl:with-param>
      </xsl:call-template>
    <xsl:text>&lt;/li&gt;</xsl:text>    
  </xsl:template>


  <xsl:template match="q:InventoryVirtualResult" mode="storeCategoryNames">
    <!-- Reference http://developer.ebay.com/devzone/xml/docs/reference/ebay/additem.html for more details -->
    <!-- Look for matching store category id, or do not use. -->
    <xsl:variable name="storeCategoryId">
      <xsl:choose>
        <xsl:when test="q:Catalog/q:Category/q:Id = ''"></xsl:when>
        <xsl:otherwise>-1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$storeCategoryId != -1">
      <a:string>
        <xsl:value-of select="$storeCategoryId"/>
      </a:string>
    </xsl:if>
  </xsl:template>

  <xsl:template name="break">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:variable name="result">
      <xsl:call-template name="break-impl">
        <xsl:with-param name="text" select="$text"/>
        <xsl:with-param name="replace" select="$replace"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="word-wrap">
      <xsl:with-param name="text" select="$result"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="word-wrap">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="string-length($text) &lt; 300">
        <xsl:value-of select="$text"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="part">
          <xsl:call-template name="substring-before-last">
            <xsl:with-param name="list" select="substring($text,1,300)"/>
            <xsl:with-param name="delimiter" select="' '"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$part"/>
        <xsl:text>&#x0d;&#x0a;</xsl:text>
        <xsl:call-template name="word-wrap">
          <xsl:with-param name="text" select="substring($text,string-length($part)+1,string-length($text))"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

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

  <xsl:template name="break-impl">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:choose>
      <xsl:when test="contains($text, $replace)">
        <xsl:value-of select="substring-before($text, $replace)"/>
        <xsl:text>&lt;br/&gt;</xsl:text>
        <xsl:call-template name="break-impl">
          <xsl:with-param name="text" select="substring-after($text,$replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="q:PhoneNumber">
    <xsl:choose>
      <xsl:when test="string-length(q:Number) = 10">
        (<xsl:value-of  select="substring(q:Number,1,3)"/>)&#160;<xsl:value-of  select="substring(q:Number,4,3)"/>-<xsl:value-of select="substring(q:Number,7,4)"/>
      </xsl:when>
      <xsl:when test="string-length(q:Number) = 7">
        <xsl:value-of  select="substring(q:Number,1,3)"/>-<xsl:value-of  select="substring(q:Number,4,4)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="q:Number"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
</xsl:stylesheet>