#[derive(Drop, Serde)]
pub struct Market {
    pub question: ByteArray,
    pub outcomes: Array<felt252>,
    pub start_time: u64,
    pub end_time: u64,
    pub is_resolved: bool,
    pub winning_outcome_id: u32,
}
