#!/bin/bash

cd /opt/
mkdir -p oreoreCA/{private,newcerts}
cd oreoreCA
echo 01 > serial

echo "type cakey.pem password" 
openssl req -x509 -days 3650 -newkey rsa:2048 -keyout private/cakey.pem -out cacert.pem -subj "/C=JP/ST=Tokyo/O=localhost/OU=test/CN=$(hostname)" 

cd /opt/oreoreCA/
echo "type newkey.pem password" 
openssl req  -newkey rsa:2048 -keyout newkey.pem -out newreq.pem -subj "/C=JP/ST=Tokyo/O=localhost/OU=test/CN=$(hostname)" 

echo "type newkey.pem password" 
openssl rsa -in newkey.pem -out nokey.pem

touch index.txt
cd /opt

echo "openssl.cnf を編集" 
cat << "EOF" > /opt/oreoreCA/openssl.cnf
HOME                    = .
RANDFILE                = $ENV::HOME/.rnd
oid_section             = new_oids
[ new_oids ]
tsa_policy1 = 1.2.3.4.1
tsa_policy2 = 1.2.3.4.5.6
tsa_policy3 = 1.2.3.4.5.7

[ ca ]
default_ca      = CA_default            # The default ca section

[ CA_default ]

dir             = /opt/oreoreCA           # Where everything is kept
certs           = $dir/certs            # Where the issued certs are kept
crl_dir         = $dir/crl              # Where the issued crl are kept
database        = $dir/index.txt        # database index file.
new_certs_dir   = $dir/newcerts         # default place for new certs.

certificate     = $dir/cacert.pem       # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
                                        # must be commented out to leave a V1 CRL
crl             = $dir/crl.pem          # The current CRL
private_key     = $dir/private/cakey.pem# The private key
RANDFILE        = $dir/private/.rand    # private random number file

x509_extensions = usr_cert              # The extentions to add to the cert

name_opt        = ca_default            # Subject Name options
cert_opt        = ca_default            # Certificate field options

default_days    = 3650                  # how long to certify for
default_crl_days= 30                    # how long before next CRL
default_md      = sha256                # use SHA-256 by default
preserve        = no                    # keep passed DN ordering

policy          = policy_match

[ policy_match ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = supplied
commonName              = optional
emailAddress            = optional

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = supplied
commonName              = optional
emailAddress            = optional

####################################################################
[ req ]
default_bits            = 2048
default_md              = sha256
default_keyfile         = privkey.pem
distinguished_name      = req_distinguished_name
attributes              = req_attributes
x509_extensions = v3_ca # The extentions to add to the self signed cert

string_mask = utf8only

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
countryName_default             = JP
countryName_min                 = 2
countryName_max                 = 2

stateOrProvinceName             = State or Province Name (full name)
stateOrProvinceName_default     = Tokyo

localityName                    = Locality Name (eg, city)
localityName_default            = Default City

0.organizationName              = Organization Name (eg, company)
0.organizationName_default      = localhost

organizationalUnitName          = Organizational Unit Name (eg, section)
organizationalUnitName_default  = Organizational Unit Name (eg, username)

commonName                      = Common Name (eg, your name or your server\'s hostname)
commonName_max                  = 64

emailAddress                    = Email Address
emailAddress_max                = 64

[ req_attributes ]
challengePassword               = A challenge password
challengePassword_min           = 4
challengePassword_max           = 20

unstructuredName                = An optional company name

[ usr_cert ]

basicConstraints=CA:FALSE

nsComment                       = "OpenSSL Generated Certificate" 

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

[ v3_req ]

basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ v3_ca ]
subjectKeyIdentifier=hash

authorityKeyIdentifier=keyid:always,issuer

basicConstraints = CA:true

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ proxy_cert_ext ]
basicConstraints=CA:FALSE

nsComment                       = "OpenSSL Generated Certificate" 

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

proxyCertInfo=critical,language:id-ppl-anyLanguage,pathlen:3,policy:foo

####################################################################
[ tsa ]

default_tsa = tsa_config1       # the default TSA section

[ tsa_config1 ]

dir             = ./oreoreCA              # TSA root directory
serial          = $dir/tsaserial        # The current serial number (mandatory)
crypto_device   = builtin               # OpenSSL engine to use for signing
signer_cert     = $dir/tsacert.pem      # The TSA signing certificate
                                        # (optional)
certs           = $dir/cacert.pem       # Certificate chain to include in reply
                                        # (optional)
signer_key      = $dir/private/tsakey.pem # The TSA private key (optional)

default_policy  = tsa_policy1           # Policy if request did not specify it
                                        # (optional)
other_policies  = tsa_policy2, tsa_policy3      # acceptable policies (optional)
digests         = sha1, sha256, sha384, sha512  # Acceptable message digests (mandatory)
accuracy        = secs:1, millisecs:500, microsecs:100  # (optional)
clock_precision_digits  = 0     # number of digits after dot. (optional)
ordering                = yes   # Is ordering defined for timestamps?
                                # (optional, default: no)
tsa_name                = yes   # Must the TSA name be included in the reply?
                                # (optional, default: no)
ess_cert_id_chain       = no    # Must the ESS cert id chain be included?
                                # (optional, default: no)

EOF


echo "00" > /opt/oreoreCA/crlnumber

echo "CSR への署名" 
openssl ca -config /opt/oreoreCA/openssl.cnf -in oreoreCA/newreq.pem -days 3650 -out oreoreCA/cert.pem  -notext
