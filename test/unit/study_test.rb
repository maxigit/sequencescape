require "test_helper"

class StudyTest < ActiveSupport::TestCase
  context "Study" do

    should_belong_to :user

    should_have_many :samples, :through => :study_samples

    context "Request" do
      setup do
        @study         = Factory :study
        @request_type    = Factory :request_type
        @request_type_2  = Factory :request_type, :name => "request_type_2", :key => "request_type_2"
        @request_type_3  = Factory :request_type, :name => "request_type_3", :key => "request_type_3"
        # Failed
        @study.requests << (Factory :cancelled_request, :study => @study, :request_type => @request_type)
        @study.requests << (Factory :cancelled_request, :study => @study, :request_type => @request_type)
        @study.requests << (Factory :cancelled_request, :study => @study, :request_type => @request_type)

        # Failed
        @study.requests << (Factory :failed_request, :study => @study, :request_type => @request_type)
        # Passed
        @study.requests << (Factory :passed_request, :study => @study, :request_type => @request_type)
        @study.requests << (Factory :passed_request, :study => @study, :request_type => @request_type)
        @study.requests << (Factory :passed_request, :study => @study, :request_type => @request_type)
        @study.requests << (Factory :passed_request, :study => @study, :request_type => @request_type_2)
        @study.requests << (Factory :passed_request, :study => @study, :request_type => @request_type_3)
        @study.requests << (Factory :passed_request, :study => @study, :request_type => @request_type_3)
        # Pending
        @study.requests << (Factory :pending_request, :study => @study, :request_type => @request_type)
        @study.requests << (Factory :pending_request, :study => @study, :request_type => @request_type_3)
        @study.save!
      end

      should "Calculate correctly and be valid" do
        assert_valid @study
        assert_equal 3, @study.cancelled_requests(@request_type)
        assert_equal 4, @study.completed_requests(@request_type)
        assert_equal 1, @study.completed_requests(@request_type_2)
        assert_equal 2, @study.completed_requests(@request_type_3)
        assert_equal 3, @study.passed_requests(@request_type)
        assert_equal 1, @study.failed_requests(@request_type)
        assert_equal 1, @study.pending_requests(@request_type)
        assert_equal 0, @study.pending_requests(@request_type_2)
        assert_equal 1, @study.pending_requests(@request_type_3)
        assert_equal 8, @study.total_requests(@request_type)
      end

    end
    
    context "Role system" do
      setup do
        @study = Factory :study, :name => "role test1"
        @another_study = Factory :study, :name => "role test2"

        @user1 = Factory :user
        @user2 = Factory :user

        @user1.has_role("owner", @study)
        @user1.has_role("follower", @study)
        @user2.has_role("follower", @study)
        @user2.has_role("manager", @study)
      end

      should "deal with followers" do
        assert ! @study.followers.empty?
        assert @study.followers.include?(@user1)
        assert @study.followers.include?(@user2)
        assert @another_study.followers.empty?
      end

      should "deal with managers" do
        assert ! @study.managers.empty?
        assert ! @study.managers.include?(@user1)
        assert @study.managers.include?(@user2)
        assert @another_study.managers.empty?
      end

      should "deal with owners" do
        assert ! @study.owners.empty?
        assert @study.owners.include?(@user1)
        assert ! @study.owners.include?(@user2)
        assert @another_study.owners.empty?
      end
    end

    context "#ethical approval?: " do
      setup do
        @study = Factory :study
      end

      context "when contains human DNA" do
        setup do
          @study.study_metadata.contains_human_dna = Study::YES
          @study.save!
        end

        context "and isn't contaminated with human DNA and does not contain sample commercially available" do
          setup do
            @study.study_metadata.contaminated_human_dna = Study::NO
            @study.study_metadata.commercially_available = Study::NO
            @study.save!
          end
          should "be in the awaiting ethical approval list" do
            assert_contains(Study.all_awaiting_ethical_approval, @study)
          end
        end

        context "and is contaminated with human DNA" do
          setup do
            @study.study_metadata.contaminated_human_dna = Study::YES
            @study.save!
          end
          should "not appear in the awaiting ethical approval list" do
            assert_does_not_contain(Study.all_awaiting_ethical_approval, @study)
          end
        end

      end
    end


    context "#unprocessed_submissions?" do
      setup do
        @study = Factory :study
        @asset = Factory :asset
      end
      context "with submissions still unprocessed" do
        setup do
          Factory::submission :study => @study, :state => 'building'
          Factory::submission :study => @study, :state => "pending", :assets => [@asset]
          Factory::submission :study => @study, :state => "processing", :assets => [@asset]
        end
        should "return true" do
          assert @study.unprocessed_submissions?
        end
      end
      context "with no submissions unprocessed" do
        setup do
          Factory::submission :study => @study, :state => "ready", :assets => [@asset]
          Factory::submission :study => @study, :state => "failed", :assets => [@asset]
        end
        should "return false" do
          assert ! @study.unprocessed_submissions?
        end
      end
      context "with no submissions at all" do
        should "return false" do
          assert ! @study.unprocessed_submissions?
        end
      end
    end

    context '#deactivate!' do
      setup do
        @study, @request_type = Factory(:study), Factory(:request_type)
        (1..2).each { |_| @study.requests << Factory(:passed_request, :request_type => @request_type) }
        (1..2).each { |_| @study.projects << Factory(:project, :enforce_quotas => true) }
        @study.projects.each { |project| Factory(:project_quota, :project => project, :request_type => @request_type, :limit => 10) }
        @study.save!

        # All that has happened to this point is just prelude
        @study.deactivate!
      end

      should 'be inactive' do
        assert @study.inactive?
      end

      should 'not cancel any associated requests' do
        assert @study.requests.all? { |request| not request.cancelled? }
      end

      should 'not alter the project quotas' do
        @study.projects.each do |project|
          assert_equal 10, project.total_quota(@request_type)
        end
      end
    end
  end
end

