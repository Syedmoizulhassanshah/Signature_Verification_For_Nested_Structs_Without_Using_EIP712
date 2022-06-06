var Web3 = require('web3');
var web3 = new Web3();
require('dotenv').config();


const encode_value = web3.eth.abi.encodeParameter(
{
    "MintData":{
        "_tokenId": 'uint256',
        "_tokenMetadataHash":'string',
    "LandData":{
         "metaData": 'string',
         "season":  'string'
     } // end of single Struct
  } // end of Nested Struct
},
 {  "_tokenId": 1,
   "_tokenMetadataHash":'QmT757cQUpNSNaEyDYYv5No7GzRogF3bnTGYxRS98EMcwt',
   "LandData":{
              "metaData": 'This is metadata',
              "season":  'Season-1'
               } // end of single Struct
 }// end of Nested Struct
);

const privateKey = process.env.PRIVATEKEY;
const structHash = web3.utils.keccak256(encode_value);
const hashGettingFromECDSAAfterPassingTheStructHash = web3.eth.accounts.hashMessage(structHash);
const signature = web3.eth.accounts.sign(structHash, privateKey);
const signerAddress = web3.eth.accounts.recover(structHash, signature.signature);


console.log("\nThis is the abi.encode value similar to on-chain:", encode_value);
console.log("\nThis is the structHash value similar to on-chain:", structHash);
console.log("\nThis is the hash value similar to the one the ECDSA method returns:", hashGettingFromECDSAAfterPassingTheStructHash);
console.log("\nThe require signature is :",signature.signature);
console.log("\nThis is the required signer address :",signerAddress);

// 0xa864f883E78F67a005a94B1B32Bf3375dfd121E6 signer address

