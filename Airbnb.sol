// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedAirbnb {
    address public owner;

    struct Property {
    address host;
    string name;
    string description;
    uint256 pricePerNight;
    uint256 cancellationFee; // Add this line
    bool isAvailable;
    uint256[] bookedDates;
    mapping(address => bool) bookedGuests;
    mapping(address => bool) disputes;
}

    struct Review {
        uint256 rating;
        bool hasReviewed;
    }


    uint256 public propertyCount;

    Property[] public properties;
    mapping(address => mapping(uint256 => Review)) public guestReviews;
        mapping(address => uint256) public guestBookings;  // Add this line
    mapping(uint256 => mapping(address => uint256)) public bookingDates;

    event PropertyListed(uint256 propertyId, string name);
    event BookingConfirmed(uint256 propertyId, address guest, uint256 checkInDate, uint256 checkOutDate);
    event ReviewPosted(uint256 propertyId, address reviewer, uint256 rating);
    event DisputeRaised(uint256 propertyId, address raiser, string reason);
    event DisputeResolved(uint256 propertyId, address resolver, bool resolved);
    event CancellationPolicyUpdated(uint256 propertyId, uint256 newCancellationFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

   function listProperty(string memory _name, string memory _description, uint256 _pricePerNight) external onlyOwner {
    Property storage newProperty = properties.push(); // Add a new Property to the array
    newProperty.host = owner;
    newProperty.name = _name;
    newProperty.description = _description;
    newProperty.pricePerNight = _pricePerNight;
    newProperty.isAvailable = true;

    // Initialize dynamic array
    newProperty.bookedDates = new uint256[](0);

    emit PropertyListed(properties.length - 1, _name);
}

// Update property details
    function updatePropertyDetails(uint256 _propertyId, string memory _name, string memory _description, uint256 _pricePerNight) external onlyOwner {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        property.name = _name;
        property.description = _description;
        property.pricePerNight = _pricePerNight;
    }

    // Extend booking duration
    function extendBooking(uint256 _propertyId, uint256 _additionalDays) external {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        require(property.bookedGuests[msg.sender], "You must have booked this property");
        uint256 checkInDate = bookingDates[_propertyId][msg.sender];
        uint256 newCheckOutDate = checkInDate + _additionalDays;
        require(newCheckOutDate > block.timestamp, "Invalid extension date");
        
        property.bookedDates.push(newCheckOutDate);
        emit BookingConfirmed(_propertyId, msg.sender, checkInDate, newCheckOutDate);
    }

    // Availability calendar
    function isPropertyAvailable(uint256 _propertyId, uint256 _date) external view returns (bool) {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        for (uint256 i = 0; i < property.bookedDates.length; i++) {
            if (property.bookedDates[i] == _date) {
                return false;
            }
        }
        return true;
    }

    // Get total number of booked properties by a guest
    function getTotalBookedProperties(address _guest) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].bookedGuests[_guest]) {
                count++;
            }
        }
        return count;
    }

    // Get guest's reviews count
    function getGuestReviewsCount(address _guest) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (guestReviews[_guest][i].hasReviewed) {
                count++;
            }
        }
        return count;
    }

    // Mark a dispute as resolved
    function markDisputeResolved(uint256 _propertyId, address _guest) external onlyOwner {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        require(property.disputes[_guest], "No dispute from this guest");

        property.disputes[_guest] = false;
        emit DisputeResolved(_propertyId, msg.sender, true);
    }

    // Get host's properties
    function getHostProperties() external view returns (uint256[] memory) {
        uint256[] memory hostProperties;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].host == msg.sender) {
                hostProperties[hostProperties.length] = i;
            }
        }
        return hostProperties;
    }


    function postReview(uint256 _propertyId, uint256 _rating) external {
        require(_propertyId < properties.length, "Invalid property ID");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(guestBookings[msg.sender] == _propertyId, "You must have booked this property to leave a review");
        require(!guestReviews[msg.sender][_propertyId].hasReviewed, "You have already posted a review");

        guestReviews[msg.sender][_propertyId] = Review({
            rating: _rating,
            hasReviewed: true
        });
        emit ReviewPosted(_propertyId, msg.sender, _rating);
    }

   function raiseDispute(uint256 _propertyId, string memory _reason) external {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        require(property.bookedGuests[msg.sender], "You must have booked this property to raise a dispute");
        require(!property.disputes[msg.sender], "You have already raised a dispute");

        property.disputes[msg.sender] = true;
        emit DisputeRaised(_propertyId, msg.sender, _reason);
    }


  function resolveDispute(uint256 _propertyId, address _guest, bool _resolved) external onlyOwner {
    require(_propertyId <= propertyCount && _propertyId > 0, "Invalid property ID");
    Property storage property = properties[_propertyId];
    require(property.disputes[_guest], "No dispute from this guest");

    if (_resolved) {
        // Implement resolution logic
        // For example, refund guest, mediate, etc.
    }

    emit DisputeResolved(_propertyId, msg.sender, _resolved);
}

 function bookProperty(uint256 _propertyId, uint256 _checkInDate, uint256 _checkOutDate) external payable {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        require(property.isAvailable, "Property is not available for booking");
        require(!property.bookedGuests[msg.sender], "You have already booked this property");
        require(_checkOutDate > _checkInDate, "Invalid check-out date");

        uint256 totalCost = property.pricePerNight * (_checkOutDate - _checkInDate);
        require(msg.value >= totalCost, "Insufficient payment");

        property.isAvailable = false;
        property.bookedDates.push(_checkInDate);
        property.bookedGuests[msg.sender] = true;

        // Store booking date for the guest
        bookingDates[_propertyId][msg.sender] = _checkInDate;

        emit BookingConfirmed(_propertyId, msg.sender, _checkInDate, _checkOutDate);
    }

    function cancelBooking(uint256 _propertyId) external {
        require(_propertyId <= propertyCount && _propertyId > 0, "Invalid property ID");
        Property storage property = properties[_propertyId];
        uint256 checkInDate = bookingDates[_propertyId][msg.sender];  // Use the bookingDates mapping
        
        require(checkInDate > 0 && checkInDate > block.timestamp, "Cannot cancel this booking");
        
        // Apply cancellation fee logic here
        uint256 refundAmount = property.pricePerNight; // Simplified: Full refund
        payable(msg.sender).transfer(refundAmount); // Convert msg.sender to payable
        property.isAvailable = true;

        // Clear the booking date for the guest
        bookingDates[_propertyId][msg.sender] = 0;
    }


      function updateCancellationPolicy(uint256 _propertyId, uint256 _newCancellationFee) external onlyOwner {
        require(_propertyId <= propertyCount && _propertyId > 0, "Invalid property ID");
        Property storage property = properties[_propertyId];
        property.cancellationFee = _newCancellationFee;
        emit CancellationPolicyUpdated(_propertyId, _newCancellationFee);
    }

    // Get guest's booking history
    function getGuestBookingHistory(address _guest) external view returns (uint256[] memory) {
        uint256[] memory bookingHistory;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].bookedGuests[_guest]) {
                bookingHistory[bookingHistory.length] = i;
            }
        }
        return bookingHistory;
    }

    // Property search with filters
    function searchProperties(string memory _keyword, uint256 _minPrice, uint256 _maxPrice) external view returns (uint256[] memory) {
        uint256[] memory matchingProperties;
        for (uint256 i = 0; i < properties.length; i++) {
            Property storage property = properties[i];
            if (
                property.isAvailable &&
                property.pricePerNight >= _minPrice &&
                property.pricePerNight <= _maxPrice &&
                (bytes(property.name).length == 0 || bytes(property.description).length == 0 || 
                 contains(property.name, _keyword) || contains(property.description, _keyword))
            ) {
                matchingProperties[matchingProperties.length] = i;
            }
        }
        return matchingProperties;
    }

       // Property ranking based on reviews
    function getTopRatedProperties(uint256 _count) external view returns (uint256[] memory) {
        uint256[] memory topRatedProperties;
        uint256 propertyListLength = properties.length; // Renamed to avoid shadowing
        for (uint256 i = 0; i < propertyListLength && i < _count; i++) {
            Property storage property = properties[i];
            if (property.isAvailable) {
                topRatedProperties[topRatedProperties.length] = i;
            }
        }
        return topRatedProperties;
    }

    
    // Mark a property as available for booking
    function markPropertyAvailable(uint256 _propertyId) external onlyOwner {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        property.isAvailable = true;
    }

    // Mark a property as unavailable for booking
    function markPropertyUnavailable(uint256 _propertyId) external onlyOwner {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        property.isAvailable = false;
    }

    // Update cancellation fee for a property
    function updateCancellationFee(uint256 _propertyId, uint256 _newCancellationFee) external onlyOwner {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        property.cancellationFee = _newCancellationFee;
        emit CancellationPolicyUpdated(_propertyId, _newCancellationFee);
    }

    // Get property details by ID
    function getPropertyDetails(uint256 _propertyId) external view returns (address, string memory, string memory, uint256, uint256, bool) {
        require(_propertyId < properties.length, "Invalid property ID");
        Property storage property = properties[_propertyId];
        return (property.host, property.name, property.description, property.pricePerNight, property.cancellationFee, property.isAvailable);
    }

    // Get total number of available properties
    function getTotalAvailableProperties() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < properties.length; i++) {
            if (properties[i].isAvailable) {
                count++;
            }
        }
        return count;
    }

// Internal function to check if a string contains a substring
    function contains(string memory _haystack, string memory _needle) internal pure returns (bool) {
        return bytes(_haystack).length >= bytes(_needle).length &&
            keccak256(bytes(_haystack)) == keccak256(bytes(_needle));
    }


    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
