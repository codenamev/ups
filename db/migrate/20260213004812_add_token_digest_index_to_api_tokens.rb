class AddTokenDigestIndexToApiTokens < ActiveRecord::Migration[8.1]
  def change
    add_index :api_tokens, :token_digest, unique: true
  end
end
