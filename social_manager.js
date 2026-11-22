const MAX_FRIENDS = 30;

function createSocialProfile({ playerId, friends = [], incomingRequests = [], blockedUsers = [], referrals = [] }) {
  return {
    playerId,
    friends: [...friends],
    incomingRequests: [...incomingRequests],
    blockedUsers: [...blockedUsers],
    referrals: [...referrals],
  };
}

function sendFriendRequest(senderProfile, receiverProfile) {
  if (!senderProfile || !receiverProfile) {
    throw new Error("بيانات ملف الصداقة غير مكتملة");
  }
  if (senderProfile.playerId === receiverProfile.playerId) {
    return { sent: false, reason: "لا يمكن إرسال طلب صداقة للنفس" };
  }
  if (receiverProfile.blockedUsers.includes(senderProfile.playerId)) {
    return { sent: false, reason: "تعذر إرسال الطلب" };
  }
  if (senderProfile.friends.includes(receiverProfile.playerId)) {
    return { sent: false, reason: "اللاعب موجود بالفعل في قائمة الأصدقاء" };
  }
  if (senderProfile.friends.length >= MAX_FRIENDS) {
    return { sent: false, reason: `الحد الأقصى للأصدقاء هو ${MAX_FRIENDS}` };
  }
  if (!receiverProfile.incomingRequests.includes(senderProfile.playerId)) {
    receiverProfile.incomingRequests.push(senderProfile.playerId);
  }
  return { sent: true, receiverId: receiverProfile.playerId };
}

function acceptFriendRequest(accepterProfile, requesterProfile) {
  if (accepterProfile.friends.length >= MAX_FRIENDS) {
    return { accepted: false, reason: `الحد الأقصى للأصدقاء هو ${MAX_FRIENDS}` };
  }
  accepterProfile.incomingRequests = accepterProfile.incomingRequests.filter(
    (id) => id !== requesterProfile.playerId
  );
  if (!accepterProfile.friends.includes(requesterProfile.playerId)) {
    accepterProfile.friends.push(requesterProfile.playerId);
  }
  if (
    requesterProfile.friends.length < MAX_FRIENDS &&
    !requesterProfile.friends.includes(accepterProfile.playerId)
  ) {
    requesterProfile.friends.push(accepterProfile.playerId);
  }
  return {
    accepted: true,
    accepterProfile,
    requesterProfile,
  };
}

function removeFriend(profile, targetId) {
  profile.friends = profile.friends.filter((id) => id !== targetId);
  return profile;
}

function blockUser(profile, targetId) {
  if (!profile.blockedUsers.includes(targetId)) {
    profile.blockedUsers.push(targetId);
  }
  profile.friends = profile.friends.filter((id) => id !== targetId);
  profile.incomingRequests = profile.incomingRequests.filter((id) => id !== targetId);
  return profile;
}

function createPrivateTableInvite({ tableId, hostId, inviteCode }) {
  return {
    inviteId: `INV-${Date.now()}`,
    tableId,
    hostId,
    inviteCode: inviteCode || `CODE-${Math.random().toString(36).slice(2, 7).toUpperCase()}`,
    createdAt: new Date().toISOString(),
  };
}

function registerReferral({ inviterProfile, inviteeId, referralRewardCoins = 500 }) {
  const entry = {
    inviteeId,
    rewardCoins: referralRewardCoins,
    createdAt: new Date().toISOString(),
  };
  inviterProfile.referrals.push(entry);
  return entry;
}

module.exports = {
  MAX_FRIENDS,
  createSocialProfile,
  sendFriendRequest,
  acceptFriendRequest,
  removeFriend,
  blockUser,
  createPrivateTableInvite,
  registerReferral,
};
