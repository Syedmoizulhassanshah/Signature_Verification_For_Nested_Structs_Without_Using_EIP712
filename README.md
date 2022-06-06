# Signature_Verification_For_Nested_Structs_Without_Using_EIP712
 
**Note:** The instructions given below are for Ubuntu 20.04 LTS (users only).

## Steps

1. Run the signature creation scripts for present in the script folder (**replace the private key with your wallet's privateKey,
   just make sure the privateKey of the wallet which you provide has fake testnet ethers in it and not the mainnet one.**).
2. Copy the land contract present in the contracts folder and deploy it on remix using your wallet address whose privatekey you used for creating signature 
   off-chain. 
3. SetmintedEnabled Value to "true".
4. Then call the mintSingleLand() Function by passing the mintdata **tuple** and the **signature** (value) you created off-chain.
5. **Result:** Token is minted now.

