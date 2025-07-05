use anchor_lang::prelude::*;

declare_id!("JC5cEVfD2Zz2DM8M8urFgASnRVxkmR6qH6heHhtaDL1X");

#[program]
pub mod hello_world {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize {}
