using HTTP
using JSON
using DataFrames

# containerAddress is the address for the dockerized signal-cli-rest-api which can be found here: https://github.com/bbernhard/signal-cli-rest-api
# Container must be running for the functions to work.
# It must also be paired with a Signal number already ($containerAddress/v1/qrcodelink?device_name=signal-api)


# Function to retrieve groups from a given containerAddress and number
# The function takes an containerAddress (String) and a number (String) as input
# and returns a DataFrame containing the groups retrieved from the API.


function retrieveGroups(containerAddress::String,number::String)
    response = HTTP.get("$containerAddress/v1/groups/$number"; header= "Content-Type: application/json")
    raw = String(response.body)
    groups = JSON.parse(raw)
    DataFrame(groups), groups

end


# Function to retrieve members of selected groups
# The function takes a vector of selected group IDs (Vector{String}) and a DataFrame of groups (DataFrame)
# and returns a vector of unique members (Vector{String}) from those groups.

function retrieveGroupsMembers(selectedGroupIDs::Vector{String}, groupsDF::DataFrame, groupsDict)
    groupIDs = groupsDF.id
    members = Vector{String}()
    for id in selectedGroupIDs
        members = vcat(members, groupsDict[findfirst(groupIDs .== id)]["members"])
    end
    members = unique(members)  # Remove duplicates
    members = String.(members)  # Convert to String type if necessary
    return members
end

# Function to send a message to a group of recipients
# The function takes an containerAddress (String), a number (String), a vector of recipient numbers (Vector{String}),

function blast(containerAddress::String, number::String, recipients::Vector{String}, message)
    HTTP.post("$containerAddress/v1/send"; header= "Content-Type: application/json", body="""{"message": "$message", "number": "$number", "recipients": $recipients}""")
end

