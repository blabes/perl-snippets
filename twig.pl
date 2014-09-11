#!/usr/bin/perl -w

use XML::Twig;

my $xml = qq{
<ns1:createRetailClaim xmlns:ns1="http://service.csi.eyemed/EyeNetBenefit"
                       xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
  <ns1:commonClaimInput>
    <ns1:claimDetails>
      <ns1:inputSource>EYENET_SAP</ns1:inputSource>
      <ns1:claimType>ADD_PAIR</ns1:claimType>
      <ns1:paperClaim>N</ns1:paperClaim>
      <ns1:groupCK>0</ns1:groupCK>
      <ns1:groupType>MVC</ns1:groupType>
      <ns1:memberId>zzzzzz</ns1:memberId>
      <ns1:retailTransId>604190563</ns1:retailTransId>
      <ns1:rxJobId>200420952</ns1:rxJobId>
      <ns1:dateOfService>2012-04-27T09:03:42</ns1:dateOfService>
      <ns1:authorizationNumber></ns1:authorizationNumber>
   </ns1:claimDetails>
 </ns1:commonClaimInput>
</ns1:createRetailClaim>
};

my $twig = XML::Twig->nparse($xml);
my $rtid = $twig->first_elt('ns1:retailTransId')->text;

print "rtid=$rtid\n";
