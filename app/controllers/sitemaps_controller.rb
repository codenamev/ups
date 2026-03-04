class SitemapsController < ActionController::Base
  def index
    @urls = [
      {
        loc: root_url,
        lastmod: 1.day.ago,
        changefreq: 'weekly',
        priority: 1.0
      },
      {
        loc: "#{root_url}pricing",
        lastmod: 1.week.ago,
        changefreq: 'monthly',
        priority: 0.8
      },
      {
        loc: "#{root_url}compare/statuspage",
        lastmod: 1.week.ago,
        changefreq: 'monthly',
        priority: 0.8
      },
      {
        loc: "#{root_url}compare/cachet",
        lastmod: 1.week.ago,
        changefreq: 'monthly',
        priority: 0.7
      },
      {
        loc: "#{root_url}compare/betteruptime",
        lastmod: 1.week.ago,
        changefreq: 'monthly',
        priority: 0.7
      },
      {
        loc: "#{root_url}use-cases/saas",
        lastmod: 1.week.ago,
        changefreq: 'monthly',
        priority: 0.7
      },
      {
        loc: "#{root_url}use-cases/api-providers",
        lastmod: 1.week.ago,
        changefreq: 'monthly',
        priority: 0.7
      },
      {
        loc: "#{root_url}use-cases/indie-hackers",
        lastmod: 1.week.ago,
        changefreq: 'monthly',
        priority: 0.7
      }
    ]

    # Include all public status pages (only those with valid slugs)
    StatusPage.find_each do |page|
      # Only include pages with valid slugs that match the route constraint
      if page.slug.match?(/\A[a-z0-9\-]+\z/)
        @urls << {
          loc: public_status_page_url(page.slug),
          lastmod: page.updated_at,
          changefreq: 'hourly',
          priority: 0.6
        }
      end
    end

    respond_to do |format|
      format.xml { render template: 'sitemaps/index', layout: false }
    end
  end
end