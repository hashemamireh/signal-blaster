using HTTP
using JSON
using DataFrames

# containerAddress is the address for the dockerized signal-cli-rest-api which can be found here: https://github.com/bbernhard/signal-cli-rest-api
# documentation for REST API can be found here: https://bbernhard.github.io/signal-cli-rest-api/#/Devices/get_v1_qrcodelink
# Container must be running for the functions to work.
# It must also be paired with a Signal number already ($containerAddress/v1/qrcodelink?device_name=signal-api)


# Function to retrieve all new groups and update membership of older ones (and other messages) from a given containerAddress
function refresh(containerAddress::String, number::String)
    HTTP.get("$containerAddress/v1/receive/$number"; header= "Content-Type: application/json")
end

# Function to retrieve groups from a given containerAddress and number
# The function takes an containerAddress (String) and a number (String) as input
# and returns a DataFrame containing the groups retrieved from the API.


function retrieveGroups(containerAddress::String,number::String)
    response = HTTP.get("$containerAddress/v1/groups/$number"; header= "Content-Type: application/json")
    raw = String(response.body)
    groups = JSON.parse(raw)
    DataFrame(groups), groups

end


# Function to retrieve members of selected groups by group ID
# The function takes a vector of selected group IDs (Vector{String}) and a DataFrame of groups (DataFrame)
# and returns a vector of unique members (Vector{String}) from those groups.
function retrieveGroupsMembersByGroupID(selectedGroupIDs::Vector{String}, groupsDF::DataFrame, groupsDict)
    groupIDs = groupsDF.id
    members = Vector{String}()
    for id in selectedGroupIDs
        members = vcat(members, groupsDict[findfirst(groupIDs .== id)]["members"])
    end
    members = unique(members)  # Remove duplicates
    members = String.(members)  # Convert to String type if necessary
    return members
end


# Function to retrieve members of selected groups by group name
# The function takes a vector of selected group names (Vector{String}) and a DataFrame of groups (DataFrame)
# and returns a vector of unique members (Vector{String}) from those groups.
function retrieveGroupsMembersByGroupName(selectedGroupNames::Vector{String}, groupsDF::DataFrame, groupsDict)
    groupNames = groupsDF.name
    members = Vector{String}()
    for name in selectedGroupNames
        members = vcat(members, groupsDict[findfirst(groupNames .== name)]["members"])
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

# Function to send a message to a group of recipients by group IDs

function blastByGroupIDs(containerAddress::String, number::String, selectedGroupIDs::Vector{String}, message)
    groupsDF, groupsDict = retrieveGroups(containerAddress, number)
    recipients = retrieveGroupsMembersByGroupID(selectedGroupIDs, groupsDF, groupsDict)
    blast(containerAddress, number, recipients, message)
end

# Function to send a message to a group of recipients by group names

function blastByGroupNames(containerAddress::String, number::String, selectedGroupNames::Vector{String}, message)
    groupsDF, groupsDict = retrieveGroups(containerAddress, number)
    recipients = retrieveGroupsMembersByGroupName(selectedGroupNames, groupsDF, groupsDict)
    blast(containerAddress, number, recipients, message)
    
end