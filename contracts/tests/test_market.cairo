fn get_validator_by_index(self: @ContractState, index: u32) -> ContractAddress {
    // Ensure the index is within bounds
    let validator_count = self.validator_count.read();
    assert(index < validator_count, 'Invalid validator index');

    // Read the validators array from storage (default value if not found)
    let validators_array: Array<ContractAddress> = self.validators_array.entry().read();

    // Return the validator at the given index
    validators_array.get(index)
}