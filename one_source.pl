#!/perl -w

my $KeyID;
my $Employees;
my $CompanyName;
my $Address1;
my $Address2;
my $Address3;
my $City;
my $StateOrProvince;
my $PostalCode;
my $Phone;
my $PrimaryURL;
my %len;
while (<>) {
  ($KeyID,
   $Employees,
   $CompanyName,
   $Address1,
   $Address2,
   $Address3,
   $City,
   $StateOrProvince,
   $PostalCode,
   $Phone,
   $PrimaryURL) = split(/\t/);
  #warn "KeyID=$KeyID\n";

  $len{KeyID} = length($KeyID) if length($KeyID) > $len{KeyID};
  $len{Employees} = length($Employees) if length($Employees) > $len{Employees};
  $len{CompanyName} = length($CompanyName) if length($CompanyName) > $len{CompanyName};
  $len{Address1} = length($Address1) if length($Address1) > $len{Address1};
  $len{Address2} = length($Address2) if length($Address2) > $len{Address2};
  $len{Address3} = length($Address3) if length($Address3) > $len{Address3};
  $len{City} = length($City) if length($City) > $len{City};
  $len{StateOrProvince} = length($StateOrProvince) if length($StateOrProvince) > $len{StateOrProvince};
  $len{PostalCode} = length($PostalCode) if length($PostalCode) > $len{PostalCode};
  $len{Phone} = length($Phone) if length($Phone) > $len{Phone};
  $len{PrimaryURL} = length($PrimaryURL) if length($PrimaryURL) > $len{PrimaryURL};
}

print "\n\n";
print "KeyID = ", $len{KeyID}, "\n";
print "Employees = ", $len{Employees}, "\n";
print "CompanyName = ", $len{CompanyName}, "\n";
print "Address1 = ", $len{Address1}, "\n";
print "Address2 = ", $len{Address2}, "\n";
print "Address3 = ", $len{Address3}, "\n";
print "City = ", $len{City}, "\n";
print "StateOrProvince = ", $len{StateOrProvince}, "\n";
print "PostalCode = ", $len{PostalCode}, "\n";
print "Phone = ", $len{Phone}, "\n";
print "PrimaryURL = ", $len{PrimaryURL}, "\n";
