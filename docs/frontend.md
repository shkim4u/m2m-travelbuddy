cd applications/TravelBuddy/ui/build
aws s3 sync . s3://travelbuddy-frontend-537682470830
aws cloudfront list-distributions
# => https://d3k8ee4wtyx7ub.cloudfront.net
# => http://d3k8ee4wtyx7ub.cloudfront.net
