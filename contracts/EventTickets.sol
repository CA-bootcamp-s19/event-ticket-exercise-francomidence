pragma solidity ^0.5.0;

/*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {
    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
    address payable public owner;

    uint256 TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint256 totalTickets;
        uint256 sales;
        mapping(address => uint256) buyers;
        bool isOpen;
    }

    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */
    event LogBuyTicket(address purchaser, uint256 ticket);
    event LogGetRefund(address refundRequester, uint256 ticket);
    event LogEndSale(address contractOwner, uint256 balance);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier OnlyOwner {
        require(owner == msg.sender, "you are not owner");
        _;
    }

    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor(
        string memory _description,
        string memory _website,
        uint256 _totalTickets
    ) public {
        owner = msg.sender;
        myEvent.description = _description;
        myEvent.website = _website;
        myEvent.totalTickets = _totalTickets;
        myEvent.sales = 0;
        myEvent.isOpen = true;
    }

    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent()
        public
        view
        returns (
            string memory description,
            string memory website,
            uint256 totalTickets,
            uint256 sales,
            bool isOpen
        )
    {
        return (
            myEvent.description,
            myEvent.website,
            myEvent.totalTickets,
            myEvent.sales,
            myEvent.isOpen
        );

    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address _buyer) public view returns (uint256) {
        return (myEvent.buyers[_buyer]);
    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */

    function buyTickets(uint256 _ticket) public payable {
        require(myEvent.isOpen == true, "Event isn't open yet.");
        require(msg.value >= (_ticket * TICKET_PRICE), "Insufficient balance");
        require(myEvent.totalTickets >= _ticket, "Out of stock!");

        myEvent.sales += _ticket;
        myEvent.buyers[msg.sender] += _ticket;
        myEvent.totalTickets -= _ticket;
        if (msg.value > (_ticket * TICKET_PRICE)) {
            uint256 change = msg.value - (_ticket * TICKET_PRICE);
            msg.sender.transfer(change);
        }

        emit LogBuyTicket(msg.sender, _ticket);
    }

    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */

    function getRefund() public payable returns (uint256, uint256) {
        require(myEvent.buyers[msg.sender] != 0, "No purchase registered");
        uint256 refund;
        uint256 refundPrice;

        //Calculating refund ticket numbers
        refund = myEvent.buyers[msg.sender];

        //Adding refunded tickets back to total tickets
        myEvent.totalTickets += refund;

        //Calculating added cost of refunded tickets
        refundPrice = refund * TICKET_PRICE;

        myEvent.buyers[msg.sender] = 0;
        msg.sender.transfer(refundPrice);

        emit LogGetRefund(msg.sender, refund);

        return (refund, refundPrice);
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */

    function endSale() public OnlyOwner {
        myEvent.isOpen = false;
        owner.transfer(address(this).balance);

        emit LogEndSale(owner, address(this).balance);
    }
}
