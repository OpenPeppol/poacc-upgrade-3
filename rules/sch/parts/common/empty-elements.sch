<?xml version="1.0" encoding="UTF-8"?>
<pattern xmlns="http://purl.oclc.org/dsdl/schematron">
 
		<rule context="//*[not(*) and not(normalize-space())]">
			<assert id="PEPPOL-COMMON-R001" test="false()" flag="fatal">[PEPPOL-COMMON-R001]-Document MUST not contain empty elements.</assert>
		</rule> 
   
</pattern>
