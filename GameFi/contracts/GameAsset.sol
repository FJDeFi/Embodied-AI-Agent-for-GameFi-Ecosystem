pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GameAsset is Ownable {
    uint256 public assetCount = 0;

    struct Asset {
        uint256 id;
        address owner;
        string name;
        string category;
        uint256 rarity;
        uint256 createdAt;
        bool isTransferable;
    }

    mapping(uint256 => Asset) public assets;
    mapping(address => uint256[]) public ownerToAssets;

    event AssetCreated(uint256 indexed id, address indexed owner, string name);
    event AssetTransferred(uint256 indexed id, address indexed from, address indexed to);
    event AssetMetadataUpdated(uint256 indexed id, string newName, string newCategory);
    event BatchOperationCompleted(uint256 count);
    event EmergencyShutdown(address initiator);

    // Optimize storage layout
    uint256 private constant MAX_RARITY = 10;
    uint256 private constant MIN_RARITY = 1;

    // Use custom errors instead of require strings
    error InvalidRarity(uint256 rarity);
    error InvalidName();
    error InvalidCategory();
    error Unauthorized();

    // Add emergency pause functionality
    bool public isPaused;
    modifier whenNotPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    function emergencyPause() external onlyOwner {
        isPaused = true;
        emit EmergencyShutdown(msg.sender);
    }

    // Create a new game asset
    function createAsset(string calldata _name, string calldata _category, uint256 _rarity) public {
        if(bytes(_name).length == 0) revert InvalidName();
        if(bytes(_category).length == 0) revert InvalidCategory();
        if(_rarity < MIN_RARITY || _rarity > MAX_RARITY) revert InvalidRarity(_rarity);
        
        assetCount++;
        assets[assetCount] = Asset(
            assetCount,
            msg.sender,
            _name,
            _category,
            _rarity,
            block.timestamp,
            true
        );
        ownerToAssets[msg.sender].push(assetCount);
        emit AssetCreated(assetCount, msg.sender, _name);
    }

    // Transfer an asset to another player
    function transferAsset(uint256 _assetId, address _to) public {
        require(assets[_assetId].owner == msg.sender, "You do not own this asset.");
        _removeAssetFromOwner(msg.sender, _assetId);
        assets[_assetId].owner = _to;
        ownerToAssets[_to].push(_assetId);
        emit AssetTransferred(_assetId, msg.sender, _to);
    }

    // Get all asset IDs owned by a player
    function getAssetsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerToAssets[_owner];
    }

    // Internal function to remove an asset from the current owner
    function _removeAssetFromOwner(address _owner, uint256 _assetId) internal {
        uint256[] storage assetIds = ownerToAssets[_owner];
        for (uint256 i = 0; i < assetIds.length; i++) {
            if (assetIds[i] == _assetId) {
                assetIds[i] = assetIds[assetIds.length - 1];
                assetIds.pop();
                break;
            }
        }
    }

    // Add batch processing with gas optimization
    function batchCreateAssets(
        string[] calldata _names,
        string[] calldata _categories,
        uint256[] calldata _rarities
    ) external whenNotPaused {
        uint256 length = _names.length;
        require(length <= 100, "Batch too large");
        require(length == _categories.length && length == _rarities.length, "Invalid input");
        
        for(uint256 i = 0; i < length;) {
            _createAsset(_names[i], _categories[i], _rarities[i]);
            unchecked { ++i; }
        }
        
        emit BatchOperationCompleted(length);
    }

    // Add batch transfer functionality and gas optimization
    function batchTransferAssets(uint256[] calldata _assetIds, address _to) external {
        uint256 length = _assetIds.length;
        for(uint256 i = 0; i < length;) {
            transferAsset(_assetIds[i], _to);
            unchecked { ++i; }
        }
    }

    // Add asset existence check
    modifier assetExists(uint256 _assetId) {
        require(_assetId > 0 && _assetId <= assetCount, "Asset does not exist");
        _;
    }
} 