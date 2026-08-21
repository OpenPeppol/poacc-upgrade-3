<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron">

    <rule context="/*">
        <assert id="PEPPOL-COMMON-R003"
                test="not(@*:schemaLocation)"
                flag="warning">[PEPPOL-COMMON-R003]-Document SHOULD not contain schema location.</assert>

    </rule>

    <rule context="cbc:IssueDate | cbc:DueDate | cbc:TaxPointDate | cbc:StartDate | cbc:EndDate | cbc:ActualDeliveryDate">
        <assert id="PEPPOL-COMMON-R030"
                test="(string(.) castable as xs:date) and (string-length(.) = 10)"
                flag="fatal">[PEPPOL-COMMON-R030]-A date must be formatted YYYY-MM-DD.</assert>
    </rule>

    <!-- Validation of ICD -->
    <rule
      context="cbc:EndpointID[@schemeID = '0088'] | cac:PartyIdentification/cbc:ID[@schemeID = '0088'] | cbc:CompanyID[@schemeID = '0088']">
      <assert id="PEPPOL-COMMON-R040"
        test="matches(normalize-space(), '^[0-9]+$') and u:gln(normalize-space())" flag="fatal">[PEPPOL-COMMON-R040]-GLN must have a valid format according to GS1 rules.</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0192'] | cac:PartyIdentification/cbc:ID[@schemeID = '0192'] | cbc:CompanyID[@schemeID = '0192']">
      <assert id="PEPPOL-COMMON-R041"
        test="matches(normalize-space(), '^[0-9]{9}$') and u:mod11(normalize-space())" flag="fatal">[PEPPOL-COMMON-R041]-Norwegian organization number MUST be stated in the correct format.</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0184'] | cac:PartyIdentification/cbc:ID[@schemeID = '0184'] | cbc:CompanyID[@schemeID = '0184']">
      <assert id="PEPPOL-COMMON-R042"
        test="(string-length(string()) = 10 and substring(string(), 1, 2) = 'DK' and string-length(translate(substring(string(), 3, 8), '1234567890', '')) = 0)
               or
              (string-length(string()) = 8) and (string-length(translate(substring(string(), 1, 8),'1234567890', '')) = 0)"
        flag="fatal">[PEPPOL-COMMON-R042]-Danish organization number (CVR) MUST be stated in the correct format.</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0096'] | cac:PartyIdentification/cbc:ID[@schemeID = '0096'] | cbc:CompanyID[@schemeID = '0096']">
      <assert id="PEPPOL-COMMON-R052"
        test="(string-length(string()) = 10) and (string-length(translate(substring(string(), 1, 10),'1234567890', '')) = 0)"
        flag="fatal">[PEPPOL-COMMON-R052]-Danish chamber of commerce number (P) MUST be stated in the correct format.</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0198'] | cac:PartyIdentification/cbc:ID[@schemeID = '0198'] | cbc:CompanyID[@schemeID = '0198']">
      <assert id="PEPPOL-COMMON-R053"
        test="(string-length(string()) = 10 and substring(string(), 1, 2) = 'DK' and string-length(translate(substring(string(), 3, 8), '1234567890', '')) = 0)"
        flag="fatal">[PEPPOL-COMMON-R053]-Danish ERSTORG number (SE) MUST be stated in the correct format.</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0208'] | cac:PartyIdentification/cbc:ID[@schemeID = '0208'] | cbc:CompanyID[@schemeID = '0208']">
      <assert id="PEPPOL-COMMON-R043"
        test="matches(normalize-space(), '^[0-9]{10}$') and u:mod97-0208(normalize-space())"
        flag="fatal">[PEPPOL-COMMON-R043]-Belgian enterprise number MUST be stated in the correct format.</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0201'] | cac:PartyIdentification/cbc:ID[@schemeID = '0201'] | cbc:CompanyID[@schemeID = '0201']">
      <assert id="PEPPOL-COMMON-R044" test="u:checkCodiceIPA(normalize-space())" flag="warning">[PEPPOL-COMMON-R044]-IPA Code (Codice Univoco Unità Organizzativa) must be stated in the correct format</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0210'] | cac:PartyIdentification/cbc:ID[@schemeID = '0210'] | cbc:CompanyID[@schemeID = '0210']">
      <assert id="PEPPOL-COMMON-R045" test="u:checkCF(normalize-space())" flag="warning">[PEPPOL-COMMON-R045]-Tax Code (Codice Fiscale) must be stated in the correct format</assert>
    </rule>
    <rule context="cbc:EndpointID[@schemeID = '9907']">
      <assert id="PEPPOL-COMMON-R046" test="u:checkCF(normalize-space())" flag="warning">[PEPPOL-COMMON-R046]-Tax Code (Codice Fiscale) must be stated in the correct format</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0211'] | cac:PartyIdentification/cbc:ID[@schemeID = '0211'] | cbc:CompanyID[@schemeID = '0211']">
      <assert id="PEPPOL-COMMON-R047" test="u:checkPIVAseIT(normalize-space())" flag="warning">[PEPPOL-COMMON-R047]-Italian VAT Code (Partita Iva) must be stated in the correct format</assert>
    </rule>
    <!--    <rule context="cbc:EndpointID[@schemeID = '9906']">
      <assert id="PEPPOL-COMMON-R048" test="u:checkPIVAseIT(normalize-space())" flag="warning">Italian
    VAT Code (Partita Iva) must be stated in the correct format</assert>
    </rule> -->
    <rule
      context="cbc:EndpointID[@schemeID = '0007'] | cac:PartyIdentification/cbc:ID[@schemeID = '0007'] | cbc:CompanyID[@schemeID = '0007']">
      <assert id="PEPPOL-COMMON-R049"
        test="string-length(normalize-space()) = 10 and string(number(normalize-space())) != 'NaN' and u:checkSEOrgnr(normalize-space())"
        flag="fatal">[PEPPOL-COMMON-R049]-Swedish organization number MUST be stated in the correct format.</assert>
    </rule>
    <rule
      context="cbc:EndpointID[@schemeID = '0151'] | cac:PartyIdentification/cbc:ID[@schemeID = '0151'] | cbc:CompanyID[@schemeID = '0151']">
      <assert id="PEPPOL-COMMON-R050"
        test="matches(normalize-space(), '^[0-9]{11}$') and u:abn(normalize-space())" flag="fatal">[PEPPOL-COMMON-R050]-Australian Business Number (ABN) MUST be stated in the correct format.</assert>
    </rule>
        <rule context="cbc:EndpointID[@schemeID = '0106'] | cac:PartyIdentification/cbc:ID[@schemeID = '0106'] | cbc:CompanyID[@schemeID = '0106']">
      <assert id="PEPPOL-COMMON-R054" test="matches(normalize-space(), '^[0-9]{8}$')" flag="warning">[PEPPOL-COMMON-R054]-Dutch Chamber of Commerce (KVK) numbers (0106) MUST be stated in the correct format (12345678).</assert>
    </rule>
    <rule context="cbc:EndpointID[@schemeID = '0190'] | cac:PartyIdentification/cbc:ID[@schemeID = '0190'] | cbc:CompanyID[@schemeID = '0190']">
      <assert id="PEPPOL-COMMON-R055" test="matches(normalize-space(), '^[0-9]{20}$')" flag="warning">[PEPPOL-COMMON-R055]-Dutch organization identification numbers (0190) MUST be stated in the correct format (12345678901234567890).</assert>
    </rule>
    <rule context="cbc:EndpointID[@schemeID = '9944'] | cac:PartyIdentification/cbc:ID[@schemeID = '9944'] | cbc:CompanyID[@schemeID = '9944']">
      <assert id="PEPPOL-COMMON-R056-1" test="matches(normalize-space(), '^NL[0-9]{9}B[0-9]{2}$')" flag="warning">[PEPPOL-COMMON-R056-1]-Dutch VAT numbers (9944) MUST be stated in the correct format (NL123456789B12).</assert>
    </rule>
    <!-- If main VAT number starts with NL, validate that too -->
    <rule context="cac:PartyTaxScheme
                   [normalize-space(cac:TaxScheme/cbc:ID) = 'VAT']
                   /cbc:CompanyID
                   [starts-with(normalize-space(.), 'NL')]">
    <assert id="PEPPOL-COMMON-R056-2" test="matches(normalize-space(.), '^NL[0-9]{9}B[0-9]{2}$')" flag="warning">[PEPPOL-COMMON-R056-2]-Dutch VAT numbers MUST have the format (NL123456789B12).</assert>
    </rule>
    <rule context="cbc:EndpointID[@schemeID = '0217'] | cac:PartyIdentification/cbc:ID[@schemeID = '0217'] | cbc:CompanyID[@schemeID = '0217']">
      <assert id="PEPPOL-COMMON-R057" test="matches(normalize-space(), '^[0-9]{12}$')" flag="warning">[PEPPOL-COMMON-R057]-Dutch Chamber of Commerce Establishment numbers (0217) MUST be stated in the correct format (123456789012).</assert>
    </rule>
    <!-- Luxembourg Register of Legal Persons number (Matricule) validation -->
    <rule context="cbc:EndpointID[@schemeID = '0240'] | cac:PartyIdentification/cbc:ID[@schemeID = '0240'] | cbc:CompanyID[@schemeID = '0240']">
      <assert id="PEPPOL-COMMON-R059"
        test="u:check-lux-0240(normalize-space(.)) = ''" flag="fatal">[PEPPOL-COMMON-R059]-Luxembourg Register of Legal Persons number (Matricule) MUST be stated in the correct format.</assert>
    </rule>
</pattern>
