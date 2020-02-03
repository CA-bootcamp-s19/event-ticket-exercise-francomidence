pragma solidity ^0.5.0;

/*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {
    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint256 PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint256 public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
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

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint256 => Event) events;

    event LogEventAdded(
        string desc,
        string url,
        uint256 ticketsAvailable,
        uint256 eventId
    );
    event LogBuyTickets(address buyer, uint256 eventId, uint256 numTickets);
    event LogGetRefund(
        address accountRefunded,
        uint256 eventId,
        uint256 numTickets
    );
    event LogEndSale(address owner, uint256 balance, uint256 eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier OnlyOwner {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(
        string memory _description,
        string memory _website,
        uint256 _totalTicket
    ) public OnlyOwner returns (uint256) {
        uint256 eventId = idGenerator;
        idGenerator++;
        events[eventId] = Event({
            description: _description,
            website: _website,
            totalTickets: _totalTicket,
            sales: 0,
            isOpen: true
        });

        emit LogEventAdded(_description, _website, _totalTicket, eventId);
        return (eventId);
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint256 _eventId)
        public
        view
        returns (string memory, string memory, uint256, uint256, bool)
    {
        Event storage ent = events[_eventId];

        return (
            ent.description,
            ent.website,
            ent.totalTickets,
            ent.sales,
            ent.isOpen
        );
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint256 _eventId, uint256 _ticket) public payable {
        Event storage ent = events[_eventId];

        require(ent.isOpen == true, "Event is closed");
        require(msg.value >= (_ticket * PRICE_TICKET), "not enough money");
        require(ent.totalTickets >= _ticket, "Out of stock");

        ent.buyers[msg.sender] += _ticket;
        ent.sales += _ticket;
        ent.totalTickets -= _ticket;
        if (msg.value > (_ticket * PRICE_TICKET)) {
            uint256 change = msg.value - (_ticket * PRICE_TICKET);
            msg.sender.transfer(change);
        }

        emit LogBuyTickets(msg.sender, _eventId, _ticket);

    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */

    function getRefund(uint256 _eventId) public payable {
        Event storage ent = events[_eventId];

        require(ent.buyers[msg.sender] != 0, "You haven't purchased a ticket!");
        uint256 refund;
        uint256 refundPrice;

        //Calculating no. of refund tickets
        refund = ent.buyers[msg.sender];

        //Adding refund tickets to total tickets
        ent.totalTickets += refund;

        //Removing refunded tickets from the sold count
        ent.sales -= refund;

        //Calculating price of refund ticket
        refundPrice = refund * PRICE_TICKET;

        ent.buyers[msg.sender] = 0;
        msg.sender.transfer(refundPrice);

        emit LogGetRefund(msg.sender, _eventId, refund);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */

    function getBuyerNumberTickets(uint256 _eventId)
        public
        view
        returns (uint256)
    {
        Event storage ent = events[_eventId];

        return (ent.buyers[msg.sender]);
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint256 _eventId) public OnlyOwner {
        Event storage ent = events[_eventId];
        uint256 balance = address(this).balance;

        ent.isOpen = false;
        owner.transfer(balance);
        emit LogEndSale(owner, balance, _eventId);
    }
}
