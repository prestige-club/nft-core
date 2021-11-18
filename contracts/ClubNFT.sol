pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ClubNFT is ERC721, Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => TokenMeta) private _tokenMeta;

    struct TokenMeta {
        uint256 id;
        uint256 price;
        string name;
        string uri;
        bool sale;
    }

    constructor() public ERC721("Yield Bunnies", "YB") {
        _setBaseURI("https://nft.cake-club.net/tokens/token?id=");
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    //Minting

    struct MintingInformation{
        uint256 curId;
        uint256 lastId;
        address asset;
        uint256 mintPrice;
    }

    mapping(address => MintingInformation[]) public mintingInfo;

    function setMintingInfo(uint256 index, uint256 firstId, uint256 lastId, address asset, uint256 mintPrice) public onlyOwner {
        MintingInformation[] storage infos = mintingInfo[asset];
        MintingInformation storage info;
        if(index >= infos.length){
            //Push element
            info = infos.push();
        }else{
            info = infos[index];
        }
        info.curId = firstId;
        info.lastId = lastId;
        info.asset = asset;
        info.mintPrice = mintPrice;
    }

    function findMintingInfo(address asset, uint256 mintPrice) public view returns (uint256 index){
        MintingInformation[] storage infos = mintingInfo[asset];
        for(uint256 i = 0 ; i < infos.length ; i++){
            MintingInformation storage info = infos[i];
            if(info.mintPrice == mintPrice && info.curId < info.lastId){
                return i;
            }
        }
        return ~uint(0); //Not found
    }

    function mint(address asset, uint256 mintPrice) public {

        uint256 index = findMintingInfo(asset, mintPrice);

        require(index < ~uint(0), "No Minting with specified Price allowed");
        MintingInformation storage info = mintingInfo[asset][index];
        require(info.mintPrice == mintPrice, "Something went wrong");

        IERC20(asset).safeTransferFrom(msg.sender, address(this), mintPrice);

        _mint(msg.sender, info.curId);

        afterMint(info.curId, asset, mintPrice);

        info.curId++;
    }

    function afterMint(uint256 tokenId, address asset, uint256 mintPrice) internal virtual {
    }

    //MarketPlace

    function getAllOnSale () public view virtual returns( TokenMeta[] memory ) {
        TokenMeta[] memory tokensOnSale = new TokenMeta[](_tokenIds.current());
        uint256 counter = 0;

        for(uint i = 1; i < _tokenIds.current() + 1; i++) {
            if(_tokenMeta[i].sale == true) {
                tokensOnSale[counter] = _tokenMeta[i];
                counter++;
            }
        }
        return tokensOnSale;
    }

    /**
     * @dev sets maps token to its price
     * @param _tokenId uint256 token ID (token number)
     * @param _sale bool token on sale
     * @param _price unit256 token price
     * 
     * Requirements: 
     * `tokenId` must exist
     * `price` must be more than 0
     * `owner` must the msg.owner
     */
    function setTokenSale(uint256 _tokenId, bool _sale, uint256 _price) public {
        require(_exists(_tokenId), "ERC721Metadata: Sale set of nonexistent token");
        require(_price > 0);
        require(ownerOf(_tokenId) == _msgSender());

        _tokenMeta[_tokenId].sale = _sale;
        setTokenPrice(_tokenId, _price);
    }

    /**
     * @dev sets maps token to its price
     * @param _tokenId uint256 token ID (token number)
     * @param _price uint256 token price
     * 
     * Requirements: 
     * `tokenId` must exist
     * `owner` must the msg.owner
     */
    function setTokenPrice(uint256 _tokenId, uint256 _price) public {
        require(_exists(_tokenId), "ERC721Metadata: Price set of nonexistent token");
        require(ownerOf(_tokenId) == _msgSender());
        _tokenMeta[_tokenId].price = _price;
    }

    function tokenPrice(uint256 tokenId) public view virtual returns (uint256) {
        require(_exists(tokenId), "ERC721Metadata: Price query for nonexistent token");
        return _tokenMeta[tokenId].price;
    }

    /**
     * @dev sets token meta
     * @param _tokenId uint256 token ID (token number)
     * @param _meta TokenMeta 
     * 
     * Requirements: 
     * `tokenId` must exist
     * `owner` must the msg.owner
     */
    function _setTokenMeta(uint256 _tokenId, TokenMeta memory _meta) private {
        require(_exists(_tokenId));
        require(ownerOf(_tokenId) == _msgSender());
        _tokenMeta[_tokenId] = _meta;
    }

    function tokenMeta(uint256 _tokenId) public view returns (TokenMeta memory) {
        require(_exists(_tokenId));
        return _tokenMeta[_tokenId];
    }

    /**
     * @dev purchase _tokenId
     * @param _tokenId uint256 token ID (token number)
     */
    function purchaseToken(uint256 _tokenId) public payable nonReentrant {
        require(msg.sender != address(0) && msg.sender != ownerOf(_tokenId));
        require(msg.value >= _tokenMeta[_tokenId].price);
        address tokenSeller = ownerOf(_tokenId);

        payable(tokenSeller).transfer(msg.value);

        setApprovalForAll(tokenSeller, true);
        _transfer(tokenSeller, msg.sender, _tokenId);
        _tokenMeta[_tokenId].sale = false;
    }

    function mintCollectable(
        address _owner, 
        string memory _tokenURI, 
        string memory _name, 
        uint256 _price, 
        bool _sale
    )
        public
        onlyOwner
        returns (uint256)
    {
        require(_price > 0);

        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_owner, newItemId);

        TokenMeta memory meta = TokenMeta(newItemId, _price, _name, _tokenURI, _sale);
        _setTokenMeta(newItemId, meta);

        return newItemId;
    }

}