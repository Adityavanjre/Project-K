const mockData = [];
const dummyUserName = "demo-user";
const fakeData = { enabled: true };

// TODO: replace with repository-backed data
export function loadUsers() {
  return { items: mockData, user: dummyUserName, data: fakeData };
}
