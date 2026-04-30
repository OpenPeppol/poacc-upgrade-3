<?xml version="1.0" encoding="UTF-8"?>	
<pattern xmlns="http://purl.oclc.org/dsdl/schematron">
	
	<rule context="cbc:CustomizationID">
			<assert id="PEPPOL-T77-R010" 
					test="starts-with(normalize-space(.), 'urn:fdc:peppol.eu:poacc:trns:punch_out:3')"
					flag="fatal">[PEPPOL-T77-R010]-Specification identifier SHALL start with the value 'urn:fdc:peppol.eu:poacc:trns:punch_out:3'.</assert>
	</rule>

	<rule context="ubl:Catalogue/cac:ValidityPeriod">
		<assert id="PEPPOL-T77-R001"
				test="(cbc:EndDate) and (number(translate(cbc:EndDate,'-','')) &gt;= number(translate(../cbc:IssueDate,'-','')))"
				flag="fatal">[PEPPOL-T77-R001]-The validity period end date SHALL NOT be earlier than the issue date.</assert>
	</rule>

	<rule context="cac:RequiredItemLocationQuantity/cac:Price">
		<assert id="PEPPOL-T77-R003"
				test="number(cbc:PriceAmount) &gt;=0"
				flag="fatal">[PEPPOL-T77-R003]-Prices of items SHALL not be negative</assert>
	</rule>

	<rule context="cac:Item">
		<assert id="PEPPOL-T77-R004"
				test="(cac:StandardItemIdentification/cbc:ID) or  (cac:SellersItemIdentification/cbc:ID)"
				flag="fatal">[PEPPOL-T77-R004]-Each item in a shopping cart line SHALL be identifiable by either "item sellers identifier" or "item standard identifier"</assert>
		<assert id="PEPPOL-T77-R005"
				test="(count(cac:ItemSpecificationDocumentReference[cbc:DocumentTypeCode = 'PRODUCT_IMAGE']) &lt;= 1)"
				flag="fatal">[PEPPOL-T77-R005]-Only one attachment may be identified as main image.</assert>
	</rule>

	<rule context="cac:CatalogueLine/cac:RequiredItemLocationQuantity">
		<assert id="PEPPOL-T77-R006"
				test="(cac:Price/cbc:BaseQuantity/@unitCode) = (cac:DeliveryUnit/cbc:BatchQuantity/@unitCode) or (not(cac:Price/cbc:BaseQuantity)) or (not(cac:DeliveryUnit/cbc:BatchQuantity))"
				flag="fatal">[PEPPOL-T77-R006]-Unit code for price base quantity SHALL be same as for batch quantity.</assert>
		<assert id="PEPPOL-T77-R002"
			test="(number(cac:Price/cbc:BaseQuantity) &gt; 0) and (number(cac:DeliveryUnit/cbc:BatchQuantity) &gt; 0) or (not(cac:Price/cbc:BaseQuantity)) or (not(cac:DeliveryUnit/cbc:BatchQuantity))"
			flag="fatal">[PEPPOL-T77-R002]-Shopping cart line quantities SHALL be greater than ZERO.</assert>
	</rule>

	<rule context="cac:Item/cac:AdditionalItemProperty[cbc:Name = 'ServiceIndicator']">
		<assert id="PEPPOL-T77-R007"
				test="(cbc:Value = 'true' or cbc:Value = 'false')"
				flag="fatal">[PEPPOL-T77-R007]-For AdditionalItemProperties where name is ServiceIndicator the value may only be "true" or "false".</assert>
	</rule>

	<rule context="cac:ClassifiedTaxCategory">
		<assert id="PEPPOL-T77-R008"
			test="cbc:Percent or (normalize-space(cbc:ID)='O')"
			flag="fatal">[PEPPOL-T77-R008]-Each Tax Category SHALL have a TAX category rate, except if the shopping cart is not subject to TAX.</assert>
		<assert id="PEPPOL-T77-R009"
			test="not(normalize-space(cbc:ID)='S') or (cbc:Percent) &gt; 0"
			flag="fatal">[PEPPOL-T77-R009]-When TAX category code is "Standard rated" (S) the TAX rate SHALL be greater than zero.</assert>
	</rule>
	
</pattern>

