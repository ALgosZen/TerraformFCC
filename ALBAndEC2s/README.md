## generate private key .pem file
### check if openssl installed - brew list openssl 
### if not installed run - brew install openssl
### upgrade if already isntalled - brew upgrade openssl

#### generate pem key file using the command below
openssl genpkey -algorithm RSA -aes-256-cbc -outform PEM -out private_key.pem -pkeyopt rsa_keygen_bits:2048

genpkey - generate private key
-algorithm RSA
- algorithm to use. other algorithms DH, EC and DSA. This website is good for roughly understanding the differences between each algorithm.