// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract WRLDLand1 is ERC721Enumerable, Ownable, ReentrancyGuard 
{
    using SafeMath for uint256;
    using ECDSA for bytes32;

    string public baseUri = "https://gateway.pinata.cloud/ipfs/";
    bool public mintEnabled = false;
    uint public totalMinted = 0;
    uint public mintSupplyCount;
    uint private ownerMintReserveCount;
    uint private ownerMintCount;
    uint private maxMintPerAddress;
    uint public whitelistAddressCount = 0;
    uint public whitelistMintCount = 0;
    uint private maxWhitelistCount = 0;

    address public artist;
    uint256 public royalityFee;
    uint256 public cost = 0.0001 ether;
    address MarketPlaceOwner;
    address signer;

    mapping(uint256 => bool) internal isSold; 

    mapping(uint256 => bool) public isListed; 


    mapping(address => uint16) private addressMintCount;
    mapping(address => bool) private whitelist;


// structs

    struct LandData {
        string metaData;
        string season;    
    }

    struct MintData {
        uint256 _tokenId;
        string _tokenMetadataHash;
        LandData _landData;
    }



   
    // Mappings to store metadata & URI/Hash
    mapping(uint => LandData) public tokenMetaData;
    mapping(uint => string) public tokenMetadataHashs;
    mapping(string => uint) private HashToTokenIds;

  // modified  constructor
    constructor(
        uint _mintSupplyCount,
        uint _ownerMintReserveCount,
        uint _maxWhitelistCount,
        uint _maxMintPerAddress) ERC721("WRLDLand", "WRLD") {

        require(_ownerMintReserveCount <= _mintSupplyCount);    
        require(_maxMintPerAddress <= _mintSupplyCount);    

        mintSupplyCount = _mintSupplyCount;
        ownerMintReserveCount = _ownerMintReserveCount;
        maxWhitelistCount = _maxWhitelistCount;
        maxMintPerAddress = _maxMintPerAddress;

    }

    






    function tokenURI(uint _tokenId) override public view returns (string memory) 
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseUri,tokenMetadataHashs[_tokenId]));      
    }
    
    modifier tokenExists(uint _tokenId) {
        require(_exists(_tokenId), "This token does not exist.");
    _;
    }
    
    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function updateMetadataHash(uint _tokenId, string calldata _tokenMetadataHash) tokenExists(_tokenId) external {
        require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");
        require(HashToTokenIds[_tokenMetadataHash] == 0, "This hash has already been assigned.");

        tokenMetadataHashs[_tokenId] = _tokenMetadataHash;
        HashToTokenIds[_tokenMetadataHash] = _tokenId;
    }
    
    function getTokenMetaData(uint _tokenId) tokenExists(_tokenId) external view returns (LandData memory ) {
        return tokenMetaData[_tokenId];
    }

    function setMintEnabled(bool _enabled) external onlyOwner {
        mintEnabled = _enabled;
    }
    
    // Method to Add user into Whitelist
    function whitelistUser(address _user) public onlyOwner {
        require(!mintEnabled, "Whitelist is not available");
        require(!whitelist[_user], "Your address is already whitelisted");
        require(whitelistAddressCount < maxWhitelistCount, "Whitelist is full");

        whitelistAddressCount++;
        whitelist[_user] = true;
    }
    
    // Method to remove user into Whitelist
    function removeWhitelistUser(address _user) public onlyOwner {
        require(!mintEnabled, "Whitelist is not available");
        require(whitelistAddressCount > 0, "The Whitelist is empty");
        whitelist[_user] = false;
        whitelistAddressCount--;
    }






// single minting function with signature verification check

    function mintSingleLand(MintData calldata _mintData,bytes calldata _signature) external nonReentrant {
        
        require(verifyOwnerSignature(keccak256(abi.encode(_mintData)), _signature), "Invalid Signature");
        require(_mintData._tokenId >= 0 && _mintData._tokenId <= mintSupplyCount, "Invalid token id.");
        require(mintEnabled, "Minting unavailable");
        require(totalMinted < mintSupplyCount, "All tokens minted");
        require(bytes(_mintData._tokenMetadataHash).length > 0, "No hash or address provided");

        if (_msgSender() != owner()) {
        require(addressMintCount[_msgSender()] < maxMintPerAddress,"You cannot mint more.");
        require(totalMinted + (ownerMintReserveCount - ownerMintCount) < mintSupplyCount,"Available tokens minted");

        // remaining mints are enough to cover remaining whitelist.
        require(
            (
                whitelist[_msgSender()] ||
                (
                totalMinted +
                (ownerMintReserveCount - ownerMintCount) +
                ((whitelistAddressCount - whitelistMintCount) * 2)
                < mintSupplyCount
                )
            ),
            "Only whitelist tokens available"
            );
        } 
        else {
            require(ownerMintCount < ownerMintReserveCount, "Owner mint limit");
        }

        tokenMetadataHashs[_mintData._tokenId] = _mintData._tokenMetadataHash;
        HashToTokenIds[_mintData._tokenMetadataHash] = _mintData._tokenId;
        tokenMetaData[_mintData._tokenId] = _mintData._landData ;

        addressMintCount[_msgSender()]++;
        totalMinted++;

        if (whitelist[_msgSender()]) {
        whitelistMintCount++;
        }

        if (_msgSender() == owner()) {
            ownerMintCount++;
        }

        _safeMint(_msgSender(), _mintData._tokenId);
    }

// multiple minting function with-out signature verification check 

    function mintmultipleLand( MintData[] calldata _mintData ) external nonReentrant {  
        for (uint i =0 ; i < _mintData.length ; i++)
        {  
         // require(verifyOwnerSignature(keccak256(abi.encode(_mintData)), _signature), "Invalid Signature");
            require(_mintData[i]._tokenId >= 0 && _mintData[i]._tokenId <= mintSupplyCount, "Invalid token id.");
            require(mintEnabled, "Minting unavailable");
            require(totalMinted < mintSupplyCount, "All tokens minted");
            require(bytes(_mintData[i]._tokenMetadataHash).length > 0, "No hash or address provided");

            if (_msgSender() != owner()) {
                require(addressMintCount[_msgSender()] < maxMintPerAddress, "You cannot mint more.");
                require(totalMinted + (ownerMintReserveCount - ownerMintCount) < mintSupplyCount, "Available tokens minted");

                // make sure remaining mints are enough to cover remaining whitelist.
                require(
                        (
                            whitelist[_msgSender()] ||
                            (
                            totalMinted +
                            (ownerMintReserveCount - ownerMintCount) +
                            ((whitelistAddressCount - whitelistMintCount) * 2)
                            < mintSupplyCount
                            )
                        ),
                        "Only whitelist tokens available"
                );
            } 
            else {
                require(ownerMintCount < ownerMintReserveCount, "Owner mint limit");
            }

            tokenMetadataHashs[_mintData[i]._tokenId] = _mintData[i]._tokenMetadataHash;
            HashToTokenIds[_mintData[i]._tokenMetadataHash] = _mintData[i]._tokenId;
            
            tokenMetaData[_mintData[i]._tokenId] = _mintData[i]._landData ;

            addressMintCount[_msgSender()]++;
            totalMinted++;

            if (whitelist[_msgSender()]) {
            whitelistMintCount++;
            }

            if (_msgSender() == owner()) {
                ownerMintCount++;
            }

            _safeMint(_msgSender(), _mintData[i]._tokenId);
        }   
    }

    function addMarketPlaceOwner(address _newOwner) public onlyOwner {
         MarketPlaceOwner = _newOwner;
    }

    function setRoyaltiesFee(uint256 _royalityFee) public onlyOwner {
        require(_royalityFee <= 10, "Royalties fee cannot be greater than 10%");
        royalityFee = _royalityFee;
    }

    function setPayoutAddressRoyalties(address _artist) public onlyOwner {
         artist = _artist;
    }

    function listNft(uint _tokenId) public returns(bool)
    {
        require(ownerOf(_tokenId) == msg.sender, "you are not owner of this token"); 
        isListed[_tokenId] = true;
        return true;
    }

    function cancelListing(uint _tokenId) public returns(bool)
    {
        require(ownerOf(_tokenId) == msg.sender, "you are not owner of this token"); 
        isListed[_tokenId] = false;
        return false;
    }

    function BuyTokens(uint256 _tokenId) payable external {
       
        require(isListed[_tokenId]==true,"NFT is not listed by its Owner");
        require(msg.value >= cost,"Kindly pay Ether to buy the NFT");
        require(msg.sender != ownerOf(_tokenId),"You cannot mint you already have this token");
         
        if(isSold[_tokenId]== false && msg.value >= cost)
        {
             isSold[_tokenId]=true;
             address _OwnerOfToken=ownerOf(_tokenId);
             uint256 _primaryFee = (msg.value* 10)/100; //10 percent commission of market place.
             uint256 _PriceOFtokenAfterMarketPalaceCommission= msg.value-_primaryFee; // 90 percent remaining value send to the owner of the NFT. 
             _safeTransfer(_OwnerOfToken,msg.sender,_tokenId," ");  
             payable (_OwnerOfToken).transfer(_PriceOFtokenAfterMarketPalaceCommission);
             primaryFee( _primaryFee); 
        }

        else if (isSold[_tokenId]==true && msg.value>= cost)
        {
            require(msg.value >= cost, "values is less than cost");      
            address _OwnerOfToken=ownerOf(_tokenId);
            uint256 _royalty =(msg.value*royalityFee)/100;
            uint256 _SecondaryFee = (msg.value* 10)/100; //10 percent commission of market place when the token is resold.
            uint256 _PriceOFtokenAfterMarketPalaceCommission= (msg.value- _royalty -_SecondaryFee); //  80 percent remaining value send to the owner of the NFT. 
            _safeTransfer(_OwnerOfToken,msg.sender,_tokenId," ");
            payable(artist).transfer(_royalty);  // transfers royalty  to the artist.
            payable (_OwnerOfToken).transfer(_PriceOFtokenAfterMarketPalaceCommission);
            secondaryFee(_SecondaryFee); // calling the function to transf er the secondary fee to the market place.
            
        }
        isListed[_tokenId] = false;
    }
         
     // transfers primaryFee to the MarketPlaceOwner.
     
    function  primaryFee( uint256 _pcommission) public 
    {
         
        payable (MarketPlaceOwner).transfer(_pcommission);
         
    }
     
    // transfers secondaryFee to the MarketPlaceOwner.
     
    function secondaryFee( uint256 _Scommission) public
    {
     
        payable (MarketPlaceOwner).transfer(_Scommission);
    }


    // new function added for testing purpose made for testing purpose
    function areYouWhitelistedaddress(address _useraddr)
        external
        view
        returns (bool)
    {
        return whitelist[_useraddr];
    }



   
  // Security
   function verifyOwnerSignature(bytes32 hash, bytes memory signature) private view returns(bool) {
    return hash.toEthSignedMessageHash().recover(signature) == owner();
  }



}  // end of contract
 
/* 
For single mint
[1,"QmT757cQUpNSNaEyDYYv5No7GzRogF3bnTGYxRS98EMcwt",["This is metadata","Season-1"]]
[2,"QmT757cQUpNSNaEyDYYv5No7GzRogF3bnTGYxRS98EMcwt",["This is metadata","Season-1"]]

For multiple Mint

[[1,"QmT757cQUpNSNaEyDYYv5No7GzRogF3bnTGYxRS98EMcwt",["This is metadata","Season-1"]],[2,"QmT757cQUpNSNaEyDYYv5No7GzRogF3bnTGYxRS98EMcwt",["This is metadata","Season-1"]]]

*/






/*  Signature Verification on-chain and off-chain data
              
                     abi.encode value on-chain 

0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000002e516d54373537635155704e534e61457944595976354e6f37477a526f674633626e5447597852533938454d63777400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000001054686973206973206d65746164617461000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008536561736f6e2d31000000000000000000000000000000000000000000000000
                     abi.encode value off-chain 

0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000002e516d54373537635155704e534e61457944595976354e6f37477a526f674633626e5447597852533938454d63777400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000001054686973206973206d65746164617461000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008536561736f6e2d31000000000000000000000000000000000000000000000000

                      structHash generated on-chain                   

 0x4e5793f15cb0feff4115497d763403839dc9fa91b85fd6e80f204a0c13bb9ec3

                      structHash generated off-chain
 0x4e5793f15cb0feff4115497d763403839dc9fa91b85fd6e80f204a0c13bb9ec3

                      ECDSA Hash on-chain
 0x57cc9c43ab1c5b4fb5ba66b6db114f7943a50f6af7055de6f41d535afa42317d
                      
                      ECDSA Hash off-chain
 0x57cc9c43ab1c5b4fb5ba66b6db114f7943a50f6af7055de6f41d535afa42317d 

                        Signature                    

 0x5678ee893bf93845766a12d144af304dd7422f0d1049eaea56f6cef447f5fe3463e84bfc79c5fff4aec893a0c6cb605c8af46cd1d4e885529128b0762b9d22e41b


*/