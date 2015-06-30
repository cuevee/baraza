authorization do
  role :guest do
    has_permission_on :home, to: [:index]
    has_permission_on :articles, to: [ :index, :show, :search ]
  end

  role :registered_user do
    includes :guest
    has_permission_on :users, to: [:change_email_form, :change_email] do
      if_attribute :id => is { user.id }
    end

    has_permission_on :articles, to: [:new, :create ]

    has_permission_on :articles, to: [:edit, :update] do
      if_attribute :user_id => is { user.id }
    end

    has_permission_on :tags, to: [:index ]
  end

  role :editor do
    includes :registered_user
  end

  role :administrator do
    includes :editor
    has_permission_on :users, to: [:new, :create, :edit, :update, :show, :destroy, :index]
  end
end
