class RemoveUniqueConstraintFromApiTokensTokenPrefix < ActiveRecord::Migration[8.1]
  def change
    # Remove the unique index on token_prefix
    remove_index :api_tokens, :token_prefix

    # Add a non-unique index on token_prefix
    add_index :api_tokens, :token_prefix
  end
end
