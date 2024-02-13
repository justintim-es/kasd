pragma solidity ^0.8.23;
import "./node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";


contract WPOD is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    constructor() ERC20("ProofOfDivision", "POD") Ownable(msg.sender) ERC20Permit("ProofOfDivision") {
    }
    function decimals() public pure override returns (uint8) {
		return 18;
	}
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
contract REFER is Ownable {
    uint public refercosts = 500000000000000;
    address[] referers;
    mapping(address => bool) fixedexchanges;
    mapping(address => address) public refered;
    mapping(address => bool) public isrefered;
    mapping(address => bool) public isreferer;
    mapping(address => mapping(address => mapping(string => bool))) redeemables;
    constructor() Ownable(msg.sender) {}

    modifier referersonly() {
        require(!isreferer[msg.sender], "You are not a referer, pay the fee to become a referer first");
        _;
    }
    modifier fixedexchangeonly() {
        require(fixedexchanges[_fixedexchange])
    }

    function set_contract(address _fixedexchange) public onlyOwner {
        fixedexchanges[_fixedexchange] = true;
    }
    function register_referer() public payable {
        require(msg.value >= (refercosts * (referers.length + 1)), "The costs of becoming a referer are 500000000000000 WEI times the amount of referers");
        require(!isreferer[msg.sender], "You already are a referer");
        referers.push(msg.sender);
        isreferer[msg.sender] = true;
    }
    function create_redeemable(address consumer, string code) public referersonly {
        redeemables[msg.sender][consumer][code] = true;
    }
    function is_redeemable(address consumer, string code) public view referersonly returns (bool) {
        return redeemables[msg.sender][consumer][code];
    }
    function refers(address shop, address referer) external {
        refered[shop] = referer;
    }



}
contract SHOP {
    REFER public refer;
    address[] public shops;
    enum ShopStatus { ZERO, REGISTERED, APPROVED, REMOVED }
    struct Shop {
        bool isrefered;
        string addressoneandtwo;
        string phonenumber;
    }
    mapping(address => Shop) public shopinfo;
    mapping(address => ShopStatus) public shopstatus;
    mapping(string => bool) public isregisterfree;
    constructor(address raddress) {
        refer = REFER(raddress);
    }

    function register_shop(string memory _address, string memory _phonenumber) public {
        require(shopstatus[msg.sender] == ShopStatus.ZERO, "Shop is already registered");
        require(!isregisterfree[_address], "Address is already registered");
        require(!isregisterfree[_phonenumber], "Phonenumber is already registered");
        shopinfo[msg.sender] = Shop({
            isrefered: false,
            addressoneandtwo: _address,
            phonenumber: _phonenumber
        });
        shopstatus[msg.sender] = ShopStatus.REGISTERED;
        isregisterfree[_address] = true;
        isregisterfree[_phonenumber] = true;
    }
    function register_shop_refered(address referer, string memory _address, string memory _phonenumber) public {
        require(isreferer[referer], "The address of the referer is not a referer");
        require(shopstatus[msg.sender] == ShopStatus.ZERO, "Shop is already registered");
        require(!isregisterfree[_address], "Address is already registered");
        require(!isregisterfree[_phonenumber], "Phonenumber is already registered");
        refer.refered[msg.sender] = referer;
        shopinfo[msg.sender] = Shop({
            isrefered: true,
            addressoneandtwo: _address,
            phonenumber: _phonenumber
        });
        shopstatus[msg.sender] = ShopStatus.REGISTERED;
        isregisterfree[_address] = true;
        isregisterfree[_phonenumber] = true;
    }
}

contract FIXEDEXCHANGE is Ownable {
    WPOD public wpod;
    REFER public refer;
    SHOP public shop;
    uint public price = 50000000000;
    uint public price_refered = 47500000000;
    uint public price_refered_discount = 45000000000;
    uint public min_refered_discount_purchase = 25000000000000000;
    uint public accuracy = 1000000000;
    uint public tbacked = 0;
    address[] public backers;
    mapping(address => uint256) public backed;

    mapping(string => Error) public errors;
    constructor(address waddress, address raddress, address saddress) Ownable(msg.sender) {
        wpod = WPOD(waddress);
        refer = REFER(raddress);
        shop = SHOP(saddress);
    }
    function back() public payable {
        require(msg.value % price == 0, "Please try to send a modular amount of ETH with our price of 50000000000 WEI");
        back_logic(msg.value / price);
        uint reward_backers = msg.value / 100 * 5;
        for (uint i = 0; i < backers.length; i++) {
            uint tt = backed[backers[i]] / (tbacked / accuracy) * (reward_backers / accuracy);
            payable(backers[i]).transfer(tt);
        }
    }
    function back_refered(address referer) public payable {
        require(msg.value % price_refered == 0, "Please try to send a modular amount of ETH with our price of 47500000000 WEI");
        require(refer.isreferer[referer], "The address of the referer is not a referer");
        back_logic(msg.value / price_refered);
        refer.refered[msg.sender] = referer;
        payable(referer).transfer(msg.value / 100 * 5);
    }
    function back_refered_discount(address referer, string code) public payable {
        require(msg.value % price_refered_first == 0, "Please try to send a modular amount of ETH with our price of 45000000000 WEI");
        require(refer.isreferer[referer], "The address of the referer is not a referer");
        require(refer.redeemables[msg.sender][code], "The code for your referers discount");
        require(msg.value >= min_refered_discount_purchase, "")
        back_logic(msg.value / price_refered_first);
        refer.refered[msg.sender] = referer;
        refer.redeemables[msg.sender][code] = false;
        payable(referer).transfer(msg.value / 100 * 5);
    }
    function back_logic(uint awpod) internal {
        bool has = false;
        for (uint i = 0; i < backers.length; i++) {
            if (backers[i] == msg.sender) {
                has = true;
            }
        }
        if (!has) {
            backers.push(msg.sender);
        }
        uint minus_fee = msg.value / 100 * 95;
        tbacked += minus_fee;
        backed[msg.sender] += minus_fee;
        wpod.transfer(msg.sender, awpod * 10 ** 18);
    }
    function sell(uint awpod) public {
        uint tpo = price * awpod / 10 ** 18;
        require(tbacked > tpo, "Insufficient Contract Balance");
        for (uint i = 0; i < backers.length; i++) {
            uint tt = backed[backers[i]] / (tbacked / accuracy) * (awpod / accuracy);
            wpod.transferFrom(msg.sender, backers[i], tt);
        }
        uint tpr = tpo / 100 * 15;
        for (uint i = 0; i < shops.length; i++) {
            address ashop = shop.shops[i];
            Shop memory shop = shop.shopinfo[ashop];
            if (shop.isrefered) {
                address referer = refer.refered[ashop];
                uint ttransfer = backed[ashop] + backed[referer] / (tbacked / accuracy) * (tpr / accuracy);
                uint ttransferreferer = ttransfer / 100 * 5;
                uint ttransfershop = ttransfer / 100 * 10;
                payable(referer).transfer(ttransferreferer);
                payable(ashop).transfer(ttransfershop);
            } else {
                uint ttransfer = backed[ashop] / (tbacked / accuracy) * (tpr / accuracy);
                payable(ashop).transfer(ttransfer / 100 * 10);
            }
        }
        uint tpomf = (tpo / 100) * 85;
        payable(msg.sender).transfer(tpomf);
    }

    function approve_shop(address shop) public onlyOwner {
        uint glb = gasleft();
        shopstatus[shop] = ShopStatus.APPROVED;
        shops.push(shop);
        uint gla = gasleft();
        payable(msg.sender).transfer(glb - gla);
    }
    function remove_shop(address shop) public onlyOwner {
        uint glb = gasleft();
        shopstatus[shop] = ShopStatus.REMOVED;
        delete shopinfo[shop];
        uint gla = gasleft();
        payable(msg.sender).transfer(glb - gla);
    }
    function referers_length() public view returns(uint) {
        return referers.length;
    }
}
