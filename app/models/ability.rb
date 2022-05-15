# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    user ||= User.new

    case user.role
      when 'su'      then su_ability
      when 'admin'   then admin_ability
      when 'pm'      then pm_ability
      when 'pa'      then pa_ability
      when 'finance' then finance_ability
      else nil
    end
  end

  def su_ability
    can :manage, :all
  end

  def admin_ability
    can :manage, User
    cannot :destroy, User
    can :manage, Candidate
    can :manage, CandidateComment
    can :manage, CandidatePaymentInfo
    can :manage, Doctor
    can :manage, Company
    can :manage, Contract
    can :manage, Project
    can :manage, ProjectCandidate
    can :manage, ProjectRequirement
    can :manage, ProjectTask
    can :manage, Finance
    can :manage, CallRecord

    can :manage, LocationDatum
    can :manage, Hospital
    can :manage, Bank
    can :manage, Industry
    can :manage, SearchAlias
    can :manage, CardTemplate
    can :manage, Extra
    # can :manage, Statistic
  end

  def pm_ability
    can_edit_my_account
    can :index, User
    can :manage, Candidate
    can :manage, CandidateComment
    can :manage, CandidatePaymentInfo
    can :manage, Doctor
    cannot :import_haodf, Doctor
    can :manage, Client
    # can [:new_client], Company
    can :manage, Project
    cannot [:billing, :billed], Project
    can :manage, ProjectCandidate
    can :manage, ProjectRequirement
    can [:show, :edit, :update, :get_base_price, :add_cost, :remove_cost, :cancel], ProjectTask
    cannot :manage, Finance
    can :manage, CallRecord

    can :manage, LocationDatum
    can :manage, Hospital
    can :manage, Bank
    can :read, Industry
  end

  def pa_ability
    can_edit_my_account
    can :index, User
    can :manage, Candidate
    can :manage, CandidateComment
    can :manage, CandidatePaymentInfo
    can :manage, Doctor
    cannot :import_haodf, Doctor
    can :manage, Client
    # can [:new_client], Company
    can [:index, :show, :add_users, :delete_user, :add_clients, :delete_client, :add_experts, :delete_expert,
         :add_project_task, :project_tasks, :experts, :work_board], Project
    can :manage, ProjectCandidate
    can :manage, ProjectRequirement
    can [:show, :edit, :update, :get_base_price, :add_cost, :remove_cost, :cancel], ProjectTask
    cannot :manage, Finance
    can :manage, CallRecord

    can :manage, LocationDatum
    can :manage, Hospital
    can :manage, Bank
    can :read, Industry
  end

  def finance_ability
    can_edit_my_account
    can [:read, :destroy, :gen_card, :project_tasks, :comments, :payment_infos, :create_client, :update_client], Candidate
    can :read, Doctor
    can :manage, Client
    can :manage, Company
    can :manage, Contract
    can [:index, :show, :edit, :add_clients, :delete_client, :project_tasks, :experts, :export_billing_excel, :close, :reopen, :billing, :billed], Project
    can :read, ProjectRequirement
    can [:show, :moveto], ProjectTask
    can :manage, Finance

    can :manage, LocationDatum
    can :read, Hospital
    can :read, Bank
    can :read, Industry
  end

  private
  def can_edit_my_account
    can [:my_account, :edit_my_account, :edit_my_password], User
  end

end

